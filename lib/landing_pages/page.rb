# frozen_string_literal: true

class LandingPages::Page
  include HasErrors
  include ActiveModel::Serialization
  
  KEY ||= "page"
  
  attr_reader :id
  
  def self.required_attrs
    %w(name path body).freeze
  end
  
  def self.discourse_attrs
    %w(theme_id group_ids).freeze
  end
  
  def self.pages_attrs
    %w(remote menu assets).freeze
  end
  
  def self.writable_attrs
    (required_attrs + discourse_attrs + pages_attrs).freeze
  end
  
  def initialize(page_id, data={})
    @id = page_id
    set(data)
  end
  
  def set(data)
    data = data.with_indifferent_access
    
    LandingPages::Page.writable_attrs.each do |attr|
      self.class.class_eval { attr_accessor attr }
      value = data[attr]
      
      if value.present?
        value = value.dasherize if attr === 'path'
        value = value.to_i if (attr === 'theme_id' && value.present?)
        value = value.map(&:to_i) if (attr === 'group_ids' && value.present?)
        
        send("#{attr}=", value)
      end
    end
  end
  
  def save
    validate

    if valid?
      data = {}
      
      LandingPages::Page.writable_attrs.each do |attr|
        value = send(attr)
        data[attr] = value if value.present?
      end

      PluginStore.set(LandingPages::PLUGIN_NAME, id, data)
    else
      false
    end
  end
  
  def validate
    self.class.required_attrs.each do |attr|
      if send(attr).blank?
        add_error(I18n.t("landing_pages.error.attr_required", attr: attr))
      end
    end
          
    if LandingPages::Page.exists?(path, attr: 'path', exclude_id: id) ||
        LandingPages::Page.application_paths.include?(path)
      add_error(I18n.t("landing_pages.error.path_exists"))
    end
  end
  
  def valid?
    errors.blank?
  end
    
  def self.find(page_id)
    if data = PluginStore.get(LandingPages::PLUGIN_NAME, page_id)
      LandingPages::Page.new(page_id, data)
    else
      nil
    end
  end
  
  def self.where(attr, value)
    PluginStoreRow.where(page_query(attr, value))
  end
  
  def self.find_by(attr, value)
    records = where(attr, value)

    if records.exists?
      params = records.pluck(:key, :value).flatten
      LandingPages::Page.new(params[0], JSON.parse(params[1]))
    else
      nil
    end
  end
  
  def self.exists?(value, attr: nil, exclude_id: nil)
    if attr
      query = page_query(attr, value)
      query += "AND key != '#{exclude_id}'" if exclude_id
    else
      query = "plugin_name = '#{LandingPages::PLUGIN_NAME}' AND key = '#{value}'"
    end
    
    PluginStoreRow.where(query).exists?
  end
  
  def self.create(params)
    params = params.with_indifferent_access
    page_id = params[:id] || "#{KEY}_#{SecureRandom.hex(16)}"
    
    data = {}
    writable_attrs.each do |attr|
      if params[attr].present?
        if attr == "theme_id"
          next unless Theme.where(id: params[attr].to_i).exists?
        end
        
        if attr == "group_ids"
          group_ids = params[attr].map(&:to_i)
          params[attr] = Group.where(id: group_ids).pluck(:id)
        end
        
        data[attr] = params[attr] if params[attr].present?
      end
    end
        
    page = LandingPages::Page.new(page_id, data)
    page.save
    page
  end
  
  def self.destroy(page_id)
    PluginStore.remove(LandingPages::PLUGIN_NAME, page_id)
  end
  
  def self.all
    PluginStoreRow.where(page_list_query).to_a.map do |row|
      new(row['key'], JSON.parse(row['value']))
    end
  end
  
  def self.page_list_query
    "plugin_name = '#{LandingPages::PLUGIN_NAME}' AND key LIKE 'page_%'"
  end
    
  def self.page_query(attr, value)
    page_list_query + " AND value::json->>'#{attr}' = '#{value}'"
  end
  
  def self.application_paths
    Rails.application.routes.routes.map do |r| 
      r.path.spec.to_s.split('/').reject(&:empty?).first
    end.uniq
  end
  
  def self.find_discourse_objects(params)
    if params[:theme].present?
      if theme = Theme.find_by(name: params[:theme])
        params[:theme_id] = theme.id
      elsif theme = Theme.find_by_id(params[:theme])
        params[:theme_id] = theme.id        
      end
      
      ## We only save theme ids of themes on the Discourse instance
      params.delete(:theme)
    end
    
    if params[:groups].present?
      params[:groups].each do |value|
        if group = Group.find_by(name: value)
          params[:group_ids] ||= []
          params[:group_ids].push(group.id)
        elsif group = Group.find_by_id(value)
          params[:group_ids] ||= []
          params[:group_ids].push(group.id)
        end
      end
      
      ## We only save group ids of groups on the Discourse instance
      params.delete(:groups)
    end
    
    params
  end
end