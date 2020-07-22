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