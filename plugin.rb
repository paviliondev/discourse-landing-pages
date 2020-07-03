# name: discourse-landing-pages
# about: Adds landing pages to Discourse
# version: 0.1
# authors: Angus McLeod
# url: https://github.com/paviliondev/discourse-landing-pages

register_asset "stylesheets/landing-pages-admin.scss"
register_svg_icon "save" if respond_to?(:register_svg_icon)
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
    ../lib/landing_pages/page.rb
    ../lib/landing_pages/page_importer.rb
    ../lib/landing_pages/page_exporter.rb
    ../lib/landing_page_constraint.rb
    ../config/routes.rb
    ../app/serializers/landing_pages/page.rb
    ../app/controllers/landing_pages/landing.rb
    ../app/controllers/landing_pages/page.rb
    ../app/jobs/send_contact_email.rb
    ../app/mailers/contact_mailer.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end
  
  module ::ApplicationHelper
    def user_details(user: user, username: username)
      return nil if user.blank? && username.blank?
      
      user = User.find_by(username: username) if user.blank?
      
      if user
        <<~HTML.html_safe
          <div class="user-details">
            <img width="45" height="45" src="#{user.avatar_template.gsub('{size}', '90')}" class="avatar">
            <span>#{user.readable_name}</span>
          </div>
        HTML
      end
    end
    
    def topic_list(category: nil)
      return [] unless category.present?
      topic_options = {
        category: category,
        no_definitions: true
      }
      TopicQuery.new(current_user, topic_options).list_latest.topics
    end
  end
end