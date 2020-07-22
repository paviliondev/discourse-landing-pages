# frozen_string_literal: true

class LandingPages::Remote
  include ActiveModel::Serialization
  include HasErrors
  
  KEY ||= 'remote'
  
  attr_accessor :url,
                :public_key,
                :private_key,
                :branch
  
  def initialize(opts)
    [:url, :public_key, :private_key, :branch].each do |key|
      instance_variable_set("@#{key}", opts[key]) if opts[key].present?
    end
  end
  
  def private
    private_key.present?
  end
  
  def save
    validate

    if valid?
      PluginStore.set(LandingPages::PLUGIN_NAME, KEY,
        url: url,
        public_key: public_key,
        private_key: private_key,
        branch: branch
      )
    end
  end
  
  def valid?
    errors.blank?
  end
  
  def validate
    unless valid_url?
      add_error(I18n.t("landing_pages.error.invalid_remote_url"))
    end
  end
  
  def valid_url?
    url =~ URI::regexp
  end
  
  def self.update(params)
    current = raw || {}
    remote = new(current.merge(params).with_indifferent_access)
    remote.save
    remote
  end
  
  def self.get
    new(raw ? raw : {}) 
  end
  
  def self.raw
    PluginStore.get(LandingPages::PLUGIN_NAME, KEY)
  end
  
  def self.destroy
    remote = self.get
    
    PluginStoreRow.transaction do
      remote_pages = LandingPages::Page.where("remote", remote.url)
      
      if remote_pages.exist?
        remote_pages.each do |record|
          value = JSON.parse(record['value'])
          value.delete("remote")
          record['value'] = value
          record.save
        end
      end
      
      PluginStore.remove(LandingPages::PLUGIN_NAME, KEY)
    end
  end
end