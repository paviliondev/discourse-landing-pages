# frozen_string_literal: true

class LandingPages::Global
  include HasErrors
  
  KEY ||= "global"
    
  def self.writable_attrs
    %w(scripts footer header).freeze
  end
  
  def initialize(data={})
    set(data)
  end
  
  def set(data)
    data = data.with_indifferent_access
    
    self.class.writable_attrs.each do |attr|
      self.class.class_eval { attr_accessor attr }
      value = data[attr]       
      send("#{attr}=", value)
    end
  end
  
  def save
    validate

    if valid?
      data = {}
      
      self.class.writable_attrs.each do |attr|
        value = send(attr)
        data[attr] = value
      end
      
      PluginStore.set(LandingPages::PLUGIN_NAME, KEY, data)
    else
      false
    end
  end
  
  def validate
    ##
  end
  
  def valid?
    errors.blank?
  end
    
  def self.find
    if data = PluginStore.get(LandingPages::PLUGIN_NAME, KEY)
      LandingPages::Global.new(data)
    else
      nil
    end
  end
  
  def self.destroy
    PluginStore.remove(LandingPages::PLUGIN_NAME, KEY)
  end
  
  def self.scripts
    global = self.find
    global ? global.scripts : []
  end
end