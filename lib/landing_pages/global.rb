# frozen_string_literal: true

class LandingPages::Global
  include HasErrors
  include ActiveModel::Serialization

  KEY = "global"

  def self.writable_attrs
    %w[scripts footer header].freeze
  end

  attr_accessor *writable_attrs

  def initialize(data = {})
    set(data)
  end

  def set(data)
    data = data.with_indifferent_access

    self.class.writable_attrs.each { |attr| send("#{attr}=", data[attr]) }
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
