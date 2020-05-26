# name: discourse-landing-pages
# about: Adds landing pages to Discourse
# version: 0.1
# authors: Angus McLeod
# url: https://github.com/paviliondev/discourse-landing-pages

register_asset "stylesheets/landing-pages.scss"
register_svg_icon "save" if respond_to?(:register_svg_icon)
add_admin_route "admin.landing_pages.title", "landing-pages"

config = Rails.application.config
plugin_asset_path = "#{Rails.root}/plugins/discourse-landing-pages/assets"
config.assets.paths << "#{plugin_asset_path}/javascripts"

if Rails.env.production?
  config.assets.precompile += %w{
    landing-page-assets.js
    landing-page-services.js
    landing-page-loader.js
  }
end

after_initialize do 
  %w[
    ../lib/landing_pages/engine.rb
    ../lib/landing_pages/page.rb
    ../lib/landing_page_constraint.rb
    ../config/routes.rb
    ../app/serializers/landing_pages/page.rb
    ../app/controllers/landing_pages/landing.rb
    ../app/controllers/landing_pages/pages.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end
end