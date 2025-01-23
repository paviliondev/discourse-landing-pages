# frozen_string_literal: true

class LandingPages::Remote
  include ActiveModel::Serialization
  include HasErrors

  KEY = "remote"

  def self.writable_attrs
    %w[url public_key private_key branch commit].freeze
  end

  attr_accessor *writable_attrs

  def initialize(opts)
    self.class.writable_attrs.each do |key|
      instance_variable_set("@#{key}", opts[key]) if opts[key].present?
    end
  end

  def private
    private_key.present?
  end

  def save
    validate

    if valid?
      remote = {}
      self.class.writable_attrs.each { |attr| remote[attr] = self.send(attr) }
      PluginStore.set(LandingPages::PLUGIN_NAME, KEY, remote)
      reset
    end
  end

  def valid?
    errors.blank?
  end

  def validate
    add_error(I18n.t("landing_pages.error.remote_invalid_url")) unless valid_url?
  end

  def valid_url?
    url =~ URI.regexp
  end

  def connected
    return false unless valid_url?

    LandingPages::GitImporter.new(url, private_key: private_key, branch: branch).connected
  end

  def commits_behind
    @commits_behind ||=
      begin
        importer = LandingPages::Importer.new(:git)
        importer.import!

        importer.handler.commits_since(commit).last.to_i if importer.report[:errors].blank?
      end
  end

  def reset
    @commits_behind = nil
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

  def self.exists?
    PluginStoreRow.exists?("plugin_name = '#{LandingPages::PLUGIN_NAME}' AND key = '#{KEY}'")
  end

  def self.raw
    PluginStore.get(LandingPages::PLUGIN_NAME, KEY)
  end

  def self.destroy
    remote = self.get

    PluginStoreRow.transaction do
      remote_pages = LandingPages::Page.where("remote", remote.url)

      if remote_pages.exists?
        remote_pages.each do |record|
          value = JSON.parse(record["value"])
          value.delete("remote")
          record["value"] = value.to_json
          record.save
        end
      end

      PluginStore.remove(LandingPages::PLUGIN_NAME, KEY)
    end
  end
end
