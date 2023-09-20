# frozen_string_literal: true

# name: discourse-landing-pages
# about: Adds landing pages to Discourse
# version: 0.2.1
# authors: Angus McLeod
# url: https://github.com/paviliondev/discourse-landing-pages

register_asset "stylesheets/landing-pages-admin.scss"
register_asset "stylesheets/landing-pages.scss"
register_asset "stylesheets/page/page.scss"

if respond_to?(:register_svg_icon)
  register_svg_icon "save"
  register_svg_icon "code-branch"
  register_svg_icon "code-commit"
end

add_admin_route "admin.landing_pages.title", "landing-pages"

extend_content_security_policy(script_src: ["https://ajax.googleapis.com"])

after_initialize do
  %w[
    ../lib/landing_pages/engine.rb
    ../lib/landing_pages/menu.rb
    ../lib/landing_pages/asset.rb
    ../lib/landing_pages/page.rb
    ../lib/landing_pages/post.rb
    ../lib/landing_pages/global.rb
    ../lib/landing_pages/remote.rb
    ../lib/landing_pages/updater.rb
    ../lib/landing_pages/import_export/git_importer.rb
    ../lib/landing_pages/import_export/zip_exporter.rb
    ../lib/landing_pages/import_export/zip_importer.rb
    ../lib/landing_pages/importer.rb
    ../lib/landing_pages/cache.rb
    ../lib/landing_email_renderer.rb
    ../lib/landing_page_constraint.rb
    ../config/routes.rb
    ../app/controllers/landing_pages/concerns/landing_helper.rb
    ../app/serializers/landing_pages/basic_page.rb
    ../app/serializers/landing_pages/page.rb
    ../app/serializers/landing_pages/menu.rb
    ../app/serializers/landing_pages/remote.rb
    ../app/serializers/landing_pages/global.rb
    ../app/controllers/landing_pages/landing.rb
    ../app/controllers/landing_pages/admin/admin.rb
    ../app/controllers/landing_pages/admin/page.rb
    ../app/controllers/landing_pages/admin/remote.rb
    ../app/controllers/landing_pages/admin/global.rb
    ../app/jobs/send_contact_email.rb
    ../app/mailers/contact_mailer.rb
    ../extensions/content_security_policy.rb
    ../extensions/upload_validator.rb
    ../extensions/upload_creator.rb
    ../extensions/user_notifications.rb
    ../extensions/user_email_job.rb
  ].each { |path| load File.expand_path(path, __FILE__) }

  add_to_class(:site, :landing_paths) { ::LandingPages.paths }
  add_to_serializer(:site, :landing_paths) { object.landing_paths }

  ::ContentSecurityPolicy::Extension.singleton_class.prepend ContentSecurityPolicyLandingPagesExtension
  ::Upload.attr_accessor :for_landing_page
  ::UploadValidator.prepend UploadValidatorLandingPagesExtension
  ::UploadCreator.prepend UploadCreatorLandingPagesExtension
  ::UserNotifications.prepend UserNotificationsLandingPagesExtension
  ::Jobs::UserEmail.prepend UserEmailJobLandingPagesExtension

  TopicQuery.add_custom_filter(:definitions_only) do |topics, query|
    if query.options[:category_id] && query.options[:definitions_only]
      topics =
        topics.where(
          "
        topics.id in (SELECT topic_id FROM categories WHERE categories.id in (?))
      ",
          Category.subcategory_ids(query.options[:category_id]),
        )
    end

    topics
  end

  TopicQuery.add_custom_filter(:filter_categories) do |topics, query|
    if query.options[:filter_categories].present?
      topics = topics.where("topics.category_id not in (?)", query.options[:filter_categories])
    end

    topics
  end

  full_path = "#{Rails.root}/plugins/discourse-landing-pages/assets/stylesheets/page/page.scss"
  Stylesheet::Importer.plugin_assets["landing_page"] = Set[full_path]

  add_to_class(:category, :landing_page_id) do
    (LandingPages::Cache.new(LandingPages::CATEGORY_IDS_KEY).read || {}).transform_keys(&:to_i)[
      self.id
    ]
  end

  add_to_class(:topic, :landing_page_url) do
    return nil if !category

    if category.landing_page_id && page = LandingPages::Page.find(category.landing_page_id)
      page.path + "/#{slug}"
    else
      nil
    end
  end

  add_to_serializer(
    :topic_view,
    :landing_page_url,
    include_condition: -> { object.topic.landing_page_url.present? },
  ) { object.topic.landing_page_url }
end
