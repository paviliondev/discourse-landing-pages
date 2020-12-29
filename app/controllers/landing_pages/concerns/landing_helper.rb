module LandingHelper
  def user_profile(user: user, username: username, add_bio: false, avatar_size: 90, top_extra: '', bottom_extra: '', show_groups: [], show_location: false)
    return nil if user.blank? && username.blank?
    
    user = User.find_by(username: username) if user.blank?
    
    if user
      bio_html = ''
      location_html = ''
      group_html = ''
      
      if show_location && user.user_profile.location
        location_html = <<~HTML.html_safe
          <div class="user-location">#{SvgSprite.raw_svg('map-marker-alt')}<span>#{user.user_profile.location}</span></div>
        HTML
      end
      
      if add_bio
        bio_html = <<~HTML.html_safe
          <div class="user-bio">
            <a href="/u/#{user.username}">#{user.user_profile.bio_excerpt(375)}</a>
          </div>
        HTML
      end
      
      if show_groups
        user_groups = user.groups.where(name: show_groups)
        
        if user_groups.present?
          group_html = <<~HTML.html_safe
            <div class="user-groups">
              #{user_groups.map { |g| "<span>#{g.title || g.full_name}</span>"}.join("")}
            </div>
          HTML
        end
      end
      
      <<~HTML.html_safe
        <div class="user-profile">
          <div class="user-top">
            <a href="/u/#{user.username}" class="user-profile">
              <img width="#{(avatar_size/2).to_s}" height="#{(avatar_size/2).to_s}" src="#{user.avatar_template.gsub('{size}', avatar_size.to_s)}" class="avatar">
              <div class="user-profile-details"><div class="user-name">#{user.readable_name}</div>#{group_html}#{location_html}</div>
            </a>
            <div class="top-extra">#{top_extra.present? ? top_extra : ''}</div>
          </div>
          #{bio_html}
          #{bottom_extra.present? ? bottom_extra : ''}
        </div>
      HTML
    end
  end
  
  def user_list(group_name: nil, order: order)
    if group_name
      group = Group.find_by(name: group_name)
      
      if group && (
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
  
  def topic_list(opts: {}, instance_var: nil, username: nil, group_name: nil)
    topics = TopicQuery.new(nil, opts)
    
    if group_name
      group = Group.find_by(name: group_name)
    end
    
    if username
      user = User.find_by(username: username)
    end
    
    if user
      list = topics.list_topics_by(user)
    elsif group
      list = topics.list_group_topics(group)
    else
      list = topics.list_latest
    end
      
    topics = list.topics
    instance_variable_set("@#{instance_var}", topics) if instance_var
    
    topics
  end
end