# frozen_string_literal: true

class LandingPages::Asset
  include HasErrors
  include ActiveModel::Serialization
  
  KEY ||= "asset"
  
  attr_reader :id,
              :upload
  
  attr_accessor :file
  
  def self.writable_attrs
    %w(name upload_id).freeze
  end
  
  def initialize(asset_id, data={})
    @id = asset_id
    set(data)
  end
  
  def set(data)
    data = data.with_indifferent_access
    
    LandingPages::Asset.writable_attrs.each do |attr|
      self.class.class_eval { attr_accessor attr }
      value = data[attr]
      
      if value.present?
        value = value.parameterize.underscore if attr === 'name'        
        send("#{attr}=", value)
      end
    end
    
    if upload_id.present?
      upload = Upload.find_by_id(upload_id)
      
      if upload
        @upload = upload
      else
        @upload_id = nil
        add_error(I18n.t("landing_pages.error.attr_required", attr: 'upload_id'))
      end
    end
  end
  
  def save
    validate

    if valid?
      data = {}
      
      LandingPages::Asset.writable_attrs.each do |attr|
        value = send(attr)
        data[attr] = value if value.present?
      end
      
      PluginStore.set(LandingPages::PLUGIN_NAME, id, data)
    else
      false
    end
  end
  
  def validate
    %w(name).each do |attr|
      if send(attr).blank?
        add_error(I18n.t("landing_pages.error.attr_required", attr: attr))
      end
    end
    
    handle_upload
  end
  
  def valid?
    errors.blank?
  end
  
  def handle_upload
    upload = nil
    
    if upload_id
      upload = Upload.find_by_id(upload_id)
      
      if upload
        local_path = Discourse.store.path_for(upload)
        
        if local_path.present?
          upload_file = File.new(local_path)
        else
          upload_file = Discourse.store.download(upload)
        end
                
        if upload_file.present?
          upload.for_landing_page = true
          Discourse.store.remove_upload(upload)
          upload.url = Discourse.store.store_upload(file, upload)
          upload.filesize = file.size
          upload.save!
        else
          upload.destroy
          upload = nil
        end
      end
    end
    
    ## Fallback attempt
    if upload.blank?
      user = Discourse.system_user
      upload = UploadCreator.new(file, File.basename(file.path), for_landing_page: true).create_for(user.id)
      @upload_id = upload.id
    end
    
    if upload.blank?
      add_error(I18n.t("landing_pages.error.attr_required", attr: 'upload_id'))
    end
  end
  
  def self.find(asset_id)
    if data = PluginStore.get(LandingPages::PLUGIN_NAME, asset_id)
      asset = new(asset_id, data)
      asset.valid? ? asset : false
    else
      nil
    end
  end
  
  def self.where(attr, value)
    PluginStoreRow.where(query(attr, value))
  end
  
  def self.find_by(attr, value)
    records = where(attr, value)
    
    if records.exists?
      params = records.pluck(:key, :value).flatten
      asset = new(params[0], JSON.parse(params[1]))
      asset.valid? ? asset : false
    else
      nil
    end
  end
  
  def self.create(params)
    params = params.with_indifferent_access
    asset_id = params[:id] || "#{KEY}_#{SecureRandom.hex(16)}"
    
    data = {}
    writable_attrs.each do |attr|
      if params[attr].present?
        data[attr] = params[attr] if params[attr].present?
      end
    end
    
    asset = new(asset_id, data)
    asset.file = params[:file] if params[:file]
    asset.save
    asset
  end
  
  def self.destroy(asset_id)
    PluginStore.remove(LandingPages::PLUGIN_NAME, asset_id)
  end
  
  def self.all
    PluginStoreRow.where(list_query).to_a.map do |row|
      new(row['key'], JSON.parse(row['value']))
    end
  end
  
  def self.query(attr, value)
    list_query + " AND value::json->>'#{attr}' = '#{value}'"
  end
  
  def self.list_query
    "plugin_name = '#{LandingPages::PLUGIN_NAME}' AND key LIKE '#{KEY}_%'"
  end
end