module ::LandingPages
  class Engine < ::Rails::Engine
    engine_name 'landing_pages'
    isolate_namespace LandingPages
  end
  
  PLUGIN_NAME ||= "landing_pages"
end