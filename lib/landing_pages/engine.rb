# frozen_string_literal: true

module ::LandingPages
  class Engine < ::Rails::Engine
    engine_name 'landing_pages'
    isolate_namespace LandingPages
  end
  
  PLUGIN_NAME ||= "landing_pages"
  PATHS_KEY ||= "paths"
  CATEGORY_IDS_KEY ||= "category_ids"
  
  def self.paths
    LandingPages::Cache.wrap(PATHS_KEY) do
      LandingPages::Page.all.map(&:path)
    end
  end
end