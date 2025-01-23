# frozen_string_literal: true

class LandingPages::Page
  include HasErrors
  include ActiveModel::Serialization

  KEY = "page"

  attr_reader :id

  def self.required_attrs
    %w[name body].freeze
  end

  def self.pages_attrs
    %w[name path parent_id remote email theme_id group_ids category_id].freeze
  end

  def self.assets_attrs
    %w[body menu assets].freeze
  end

  def self.writable_attrs
    (pages_attrs + assets_attrs).freeze
  end

  attr_accessor *writable_attrs

  def initialize(page_id, data = {})
    @id = page_id
    set(data)
  end

  def set(data)
    data = data.with_indifferent_access

    self.class.writable_attrs.each do |attr|
      value = data[attr]

      if value.present?
        value = value.dasherize if "path" == attr
        value = value.to_i if %w[category_id theme_id].include?(attr)
        value = value.map(&:to_i) if "group_ids" == attr
      end

      send("#{attr}=", value)
    end
  end

  def save
    validate

    if valid?
      data = {}
      self.class.writable_attrs.each { |attr| data[attr] = send(attr) }

      PluginStore.set(LandingPages::PLUGIN_NAME, id, data)

      after_save
    else
      false
    end
  end

  def after_save
    if category_id
      cache = LandingPages::Cache.new(LandingPages::CATEGORY_IDS_KEY)
      category_id_map = cache.read || {}
      category_id_map[category_id] = id
      cache.write(category_id_map)
    end
  end

  def destroy
    after_destroy if PluginStore.remove(LandingPages::PLUGIN_NAME, id)
  end

  def after_destroy
    LandingPages::Cache.new(LandingPages::CATEGORY_IDS_KEY).delete
  end

  def validate
    self.class.required_attrs.each do |attr|
      add_error(I18n.t("landing_pages.error.attr_required", attr: attr)) if send(attr).blank?
    end

    if self.class.exists?(name, attr: "name", exclude_id: id)
      add_error(I18n.t("landing_pages.error.attr_exists", attr: "name"))
    end

    if !parent_id && path.blank?
      add_error(I18n.t("landing_pages.error.attr_required", attr: "path"))
    end

    if !parent_id && path.present? && self.class.path_exists?(path, id)
      add_error(I18n.t("landing_pages.error.attr_exists", attr: "path"))
    end
  end

  def valid?
    errors.blank?
  end

  def parent
    parent_id.present? ? self.class.find(parent_id) : nil
  end

  def self.find(page_id)
    return nil if !page_id

    if data = PluginStore.get(LandingPages::PLUGIN_NAME, page_id)
      new(page_id, data)
    else
      nil
    end
  end

  def self.where(attr, value)
    ::PluginStoreRow.where(page_query(attr), value)
  end

  def self.find_by(attr, value)
    records = self.where(attr, value)

    if records.exists?
      opts = records.pluck(:key, :value).flatten
      new(opts[0], JSON.parse(opts[1]))
    else
      nil
    end
  end

  def self.exists?(value, attr: nil, exclude_id: nil)
    if attr
      query = page_query(attr)
      query += " AND key != '#{exclude_id}'" if exclude_id
    else
      query = "plugin_name = '#{LandingPages::PLUGIN_NAME}' AND key = ?"
    end

    ::PluginStoreRow.where(query, value).exists?
  end

  def self.create(opts)
    opts = opts.with_indifferent_access
    page_id = opts[:id] || "#{KEY}_#{SecureRandom.hex(16)}"

    data = {}
    writable_attrs.each do |attr|
      if opts[attr].present?
        if attr === "theme_id"
          next unless Theme.where(id: opts[attr]).exists?
        end

        if attr === "parent_id"
          next unless self.exists?(opts[attr])
        end

        if attr === "category_id"
          next unless Category.where(id: opts[attr]).exists?
        end

        opts[attr] = Group.where(id: opts[attr]).pluck(:id) if attr === "group_ids"

        data[attr] = opts[attr] if opts[attr].present?
      end
    end

    page = new(page_id, data)
    page.save
    page
  end

  def self.all
    PluginStoreRow
      .where(page_list_query)
      .to_a
      .map { |row| new(row["key"], JSON.parse(row["value"])) }
  end

  def self.page_list_query
    "plugin_name = '#{LandingPages::PLUGIN_NAME}' AND key LIKE 'page_%'"
  end

  def self.page_query(attr)
    page_list_query + " AND value::json->>'#{attr}' = ?"
  end

  def self.find_child_page(path)
    query =
      "#{page_list_query} AND value::json->>'parent_id' IN (SELECT key FROM plugin_store_rows WHERE #{page_query("path")})"
    records = PluginStoreRow.where(query, path)

    if records.exists?
      opts = records.pluck(:key, :value).flatten
      new(opts[0], JSON.parse(opts[1]))
    else
      nil
    end
  end

  def self.path_exists?(path, page_id)
    self.exists?(path, attr: "path", exclude_id: page_id) || self.application_paths.include?(path)
  end

  def self.application_paths
    Rails
      .application
      .routes
      .routes
      .map { |r| r.path.spec.to_s.split("/").reject(&:empty?).first }
      .uniq
  end

  def self.find_discourse_objects(opts)
    if opts[:theme] != nil
      if theme = Theme.find_by(name: opts[:theme])
        opts[:theme_id] = theme.id
      elsif theme = Theme.find_by_id(opts[:theme])
        opts[:theme_id] = theme.id
      end

      opts.delete(:theme)
    end

    if opts[:groups] != nil
      opts[:group_ids] = []

      opts[:groups].each do |value|
        if group = Group.find_by(name: value)
          opts[:group_ids].push(group.id)
        elsif group = Group.find_by_id(value)
          opts[:group_ids].push(group.id)
        end
      end

      opts.delete(:groups)
    end

    if opts[:category] != nil
      if category = Category.find_by(slug: opts[:category])
        opts[:category_id] = category.id
      elsif category = Category.find_by_id(opts[:category])
        opts[:category_id] = category.id
      end

      opts.delete(:category)
    end

    opts
  end
end
