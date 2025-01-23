# frozen_string_literal: true

module LandingHelper
  def user_profile(
    user,
    include_avatar: true,
    add_bio: false,
    avatar_size: 90,
    top_extra: "",
    bottom_extra: "",
    profile_details: true,
    show_groups: [],
    show_location: false
  )
    return nil if user.blank?

    if user
      bio_html = ""
      location_html = ""
      group_html = ""
      avatar_html = ""
      profile_details_html = ""

      if profile_details
        location_html = <<~HTML.html_safe if show_location && user.user_profile.location
            <div class="user-location">#{SvgSprite.raw_svg("map-marker-alt")}<span>#{user.user_profile.location}</span></div>
          HTML

        if show_groups
          user_groups = user.groups.where(name: show_groups)

          group_html = <<~HTML.html_safe if user_groups.present?
              <div class="user-groups">
                #{user_groups.map { |g| "<span>#{g.full_name}</span>" }.join("")}
              </div>
            HTML
        end

        profile_details_html =
          "<div class='user-profile-details'><div class='user-name'>#{user.readable_name}</div>#{group_html}#{location_html}</div>"
      end

      bio_html = <<~HTML.html_safe if add_bio
          <div class="user-bio">
            <a href="/u/#{user.username}">#{user.user_profile.bio_excerpt(375)}</a>
          </div>
        HTML

      if include_avatar
        avatar_html =
          "<img width='#{(avatar_size / 2)}' height='#{(avatar_size / 2)}' src='#{user.avatar_template.gsub("{size}", avatar_size.to_s)}' class='avatar'>"
      end

      <<~HTML.html_safe
        <div class="user-profile">
          <div class="user-top">
            <a href="/u/#{user.username}" class="user-profile" title="#{user.readable_name}">
              #{avatar_html}
              #{profile_details_html}
            </a>
            <div class="top-extra">#{top_extra.present? ? top_extra : ""}</div>
          </div>
          #{bio_html}
          #{bottom_extra.present? ? bottom_extra : ""}
        </div>
      HTML
    end
  end

  def user_list(group_name: nil, order: "DESC")
    if group_name
      group = Group.find_by(name: group_name)

      if group &&
           (
             (group.visibility_level == Group.visibility_levels[:public]) ||
               (@group && @group.id == group.id)
           )
        users = group.users
        users = users.order(ActiveRecord::Base.sanitize_sql_array([*order])) if order
        return users.to_ary
      end
    end

    []
  end

  def topic_list(opts: {}, list_opts: {}, item_opts: {})
    list_opts[:per_page] = 30 if list_opts[:per_page].blank?
    list_opts[:category] = -1 if list_opts[:category].blank?
    topics = list_topics(opts, list_opts)

    instance_variable_set("@#{opts[:instance_var]}", topics) if opts[:instance_var]

    if opts[:render_list]
      list_end = topics.count < list_opts[:per_page]

      <<~HTML.html_safe
        <div class="topic-list"
             data-scrolling-topic-list=true
             data-page-id="#{@page.id}"
             data-list-end=#{list_end}
             data-list-category="#{list_opts[:category]}"
             data-list-per-page="#{list_opts[:per_page]}"
             data-list-page="0"
             data-list-no-definitions="#{list_opts[:no_definitions]}"
             data-item-classes="#{item_opts[:classes]}"
             data-item-excerpt-length="#{item_opts[:excerpt_length]}"
             data-item-include-avatar="#{item_opts[:include_avatar]}"
             data-item-avatar-size="#{item_opts[:avatar_size]}">
          #{list_item_html(topics, item_opts)}
        </div>
      HTML
    else
      topics
    end
  end

  def set_parent_page(parent_id)
    if parent_page = LandingPages::Page.find(parent_id)
      instance_variable_set("@parent_page", parent_page)
    end
  end

  def set_category_user(category_id, user: current_user)
    if user && category = Category.find_by(id: category_id)
      category_user = CategoryUser.find_by(category_id: category.id, user_id: user.id)

      if !category_user
        category_user =
          CategoryUser.create!(
            user: user,
            category_id: category.id,
            notification_level: CategoryUser.notification_levels[:regular],
          )
      end

      instance_variable_set("@category_user", category_user)
    end
  end

  def get_topic_view(id_or_slug, opts: {}, instance_var: nil, set_page_title: false)
    return nil if id_or_slug.blank?
    topic = Topic.where("id = ? or slug = ?", id_or_slug.to_i, id_or_slug.to_s)

    if topic.exists?
      topic = topic.first
      topic_view = TopicView.new(topic, current_user, opts)
      instance_variable_set("@#{instance_var}", topic_view) if instance_var
      @page_title = SiteSetting.title + " | #{topic.title}" if set_page_title
      topic_view
    end
  end
end
