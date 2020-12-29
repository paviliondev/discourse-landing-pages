# frozen_string_literal: true

# name: discourse-landing-pages
# about: Adds landing pages to Discourse
# version: 0.1
# authors: Angus McLeod
# url: https://github.com/paviliondev/discourse-landing-pages

register_asset "stylesheets/landing-pages-admin.scss"

if respond_to?(:register_svg_icon)
  register_svg_icon "save" 
  register_svg_icon "code-branch"
  register_svg_icon "code-commit"
end

add_admin_route "admin.landing_pages.title", "landing-pages"
gem "jquery-rails", "4.4.0"

config = Rails.application.config
plugin_asset_path = "#{Rails.root}/plugins/discourse-landing-pages/assets"
config.assets.paths << "#{plugin_asset_path}/javascripts"
config.assets.paths << "#{plugin_asset_path}/stylesheets"

if Rails.env.production?
  config.assets.precompile += %w{
    landing-page-assets.js
    landing-page-services.js
    landing-page-loader.js
    page/common.js
    page/desktop.js
    page/mobile.js
    vendor/waypoints.min.js
    stylesheets/page/variables.scss
    stylesheets/page/buttons.scss
    stylesheets/page/header.scss
    stylesheets/page/contact-form.scss
    stylesheets/page/list.scss
    stylesheets/page/post.scss
    stylesheets/page/page.scss
  }
end

after_initialize do 
  %w[
    ../lib/landing_pages/engine.rb
    ../lib/landing_pages/menu.rb
    ../lib/landing_pages/asset.rb
    ../lib/landing_pages/page.rb
    ../lib/landing_pages/pages.rb
    ../lib/landing_pages/remote.rb
    ../lib/landing_pages/updater.rb
    ../lib/landing_pages/import_export/git_importer.rb
    ../lib/landing_pages/import_export/zip_exporter.rb
    ../lib/landing_pages/import_export/zip_importer.rb
    ../lib/landing_pages/importer.rb
    ../lib/landing_page_constraint.rb
    ../config/routes.rb
    ../app/controllers/landing_pages/concerns/landing_helper.rb
    ../app/serializers/landing_pages/page.rb
    ../app/serializers/landing_pages/menu.rb
    ../app/serializers/landing_pages/remote.rb
    ../app/controllers/landing_pages/landing.rb
    ../app/controllers/landing_pages/admin/admin.rb
    ../app/controllers/landing_pages/admin/page.rb
    ../app/controllers/landing_pages/admin/remote.rb
    ../app/jobs/send_contact_email.rb
    ../app/mailers/contact_mailer.rb
    ../extensions/upload_validator.rb
    ../extensions/upload_creator.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end
  
  TopicQuery.add_custom_filter(:definitions) do |results, query|
    if query.options[:definitions]
      results = results.where('COALESCE(categories.topic_id, 0) = topics.id')
    end
    results
  end
  
  on(:before_email_send) do |message, email_type|
    if message.subject == I18n.t("contact_mailer.title")
      message.header[:return_path].value = message.header[:reply_to].value
    end
  end
  
  ::Upload.attr_accessor :for_landing_page
  ::UploadValidator.prepend UploadValidatorLandingPagesExtension
  ::UploadCreator.prepend UploadCreatorLandingPagesExtension
end