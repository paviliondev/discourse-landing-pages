class LandingPages::Page
  include HasErrors
  include ActiveModel::Serialization
  
  KEY ||= "page"
  
  attr_reader :id
  
  def meta_attrs
    %w(name path theme_id).freeze
  end
  
  def file_attrs
    %w(body menu).freeze
  end
  
  def writable_attrs
    (meta_attrs + file_attrs).freeze
  end
  
  def initialize(page_id, data={})
    @id = page_id
    set(data)
  end
  
  def set(data)
    writable_attrs.each do |attr|
      self.class.class_eval { attr_accessor attr }
      value = data[attr]
      value = value.dasherize if attr === 'path'
      value = value.to_i if (attr === 'theme_id' && value.present?)
      
      if value.present?
        send("#{attr}=", value)
      end
    end
  end
  
  def save
    validate

    if valid?
      data = {}
      
      writable_attrs.each do |attr|
        data[attr] = send(attr)
      end
      
      PluginStore.set(
        LandingPages::PLUGIN_NAME,
        LandingPages::Page.build_key(id),
        data
      )
    else
      false
    end
  end
  
  def validate
    %w(name path body).each do |attr|
      if send(attr).blank?
        add_error(I18n.t("landing_pages.error.attr_required", attr: attr))
      end
    end
          
    if LandingPages::Page.exists?(path, 'path', exclude_id: id) ||
       LandingPages::Page.application_paths.include?(path)
      add_error(I18n.t("landing_pages.error.path_exists"))
    end
  end
  
  def valid?
    errors.blank?
  end
    
  def self.find(page_id)
    if data = PluginStore.get(LandingPages::PLUGIN_NAME, build_key(page_id))
      LandingPages::Page.new(page_id, data)
    else
      nil
    end
  end
  
  def self.find_by_path(path)
    record = PluginStoreRow.where(page_query('path', path))
    
    if record.exists?
      params = record.pluck(:key, :value).flatten
      LandingPages::Page.new(params[0], JSON.parse(params[1]))
    else
      nil
    end
  end
  
  def self.exists?(value, attr=nil, opts={})
    if attr
      query = page_query(attr, value)
      
      if opts[:exclude_id]
        query += "AND key != '#{build_key(opts[:exclude_id])}'"
      end
    else
      query = "plugin_name = '#{LandingPages::PLUGIN_NAME}' AND key = '#{build_key(value)}'"
    end
    
    PluginStoreRow.where(query).exists?
  end
  
  def self.create(data)
    page = LandingPages::Page.new(SecureRandom.hex(6), data)
    page.save
    page
  end
  
  def self.destroy(page_id)
    PluginStore.remove(LandingPages::PLUGIN_NAME, LandingPages::Page.build_key(page_id))
  end
  
  def self.export(page_id)
  
  end
  
  def self.all
    PluginStoreRow.where("plugin_name = '#{LandingPages::PLUGIN_NAME}'").to_a
      .map { |row| new(row['key'].split('_').last, JSON.parse(row['value'])) }
  end
    
  def self.page_query(attr, value)
    "plugin_name = '#{LandingPages::PLUGIN_NAME}' AND value::json->>'#{attr}' = '#{value}'"
  end
  
  def self.build_key(page_id)
    "#{KEY}_#{page_id}".freeze
  end
  
  def self.application_paths
    Rails.application.routes.routes.map do |r| 
      r.path.spec.to_s.split('/').reject(&:empty?).first
    end.uniq
  end
end