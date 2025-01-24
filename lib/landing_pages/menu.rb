# frozen_string_literal: true

class LandingPages::Menu
  include HasErrors
  include ActiveModel::Serialization

  KEY = "menu"

  attr_reader :id

  def self.writable_attrs
    %w[name items].freeze
  end

  attr_accessor *writable_attrs

  def initialize(menu_id, data = {})
    @id = menu_id
    set(data)
  end

  def set(data)
    data = data.with_indifferent_access

    self.class.writable_attrs.each do |attr|
      value = data[attr]

      if value.present?
        value = value.parameterize.underscore if attr === "name"

        send("#{attr}=", value)
      end
    end
  end

  def save
    validate

    if valid?
      data = {}

      LandingPages::Menu.writable_attrs.each do |attr|
        value = send(attr)
        data[attr] = value if value.present?
      end

      PluginStore.set(LandingPages::PLUGIN_NAME, id, data)
    else
      false
    end
  end

  def validate
    %w[name items].each do |attr|
      add_error(I18n.t("landing_pages.error.attr_required", attr: attr)) if send(attr).blank?
    end
  end

  def valid?
    errors.blank?
  end

  def self.find(menu_id)
    if data = PluginStore.get(LandingPages::PLUGIN_NAME, menu_id)
      new(menu_id, data)
    else
      nil
    end
  end

  def self.where(attr, value)
    PluginStoreRow.where(menu_query(attr, value))
  end

  def self.find_by(attr, value)
    records = where(attr, value)

    if records.exists?
      params = records.pluck(:key, :value).flatten
      new(params[0], JSON.parse(params[1]))
    else
      nil
    end
  end

  def self.create(params)
    params = params.with_indifferent_access
    menu_id = params[:id] || "#{KEY}_#{SecureRandom.hex(16)}"
    menu = new(menu_id, params)
    menu.save
    menu
  end

  def self.exists?(menu_id)
    PluginStoreRow.exists?("plugin_name = '#{LandingPages::PLUGIN_NAME}' AND key = 'menu_id'")
  end

  def self.destroy(menu_id)
    PluginStore.remove(LandingPages::PLUGIN_NAME, menu_id)
  end

  def self.all
    PluginStoreRow
      .where(menu_list_query)
      .to_a
      .map { |row| new(row["key"], JSON.parse(row["value"])) }
  end

  def self.menu_query(attr, value)
    menu_list_query + " AND value::json->>'#{attr}' = '#{value}'"
  end

  def self.menu_list_query
    "plugin_name = '#{LandingPages::PLUGIN_NAME}' AND key LIKE '#{KEY}_%'"
  end
end
