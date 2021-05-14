class LandingEmailRenderer < ActionView::Base
  include ApplicationHelper
  include UserNotificationsHelper
  include EmailHelper

  LOCK = Mutex.new

  def self.render(*args)
    LOCK.synchronize do
      @instance ||= LandingEmailRenderer.with_empty_template_cache.with_view_paths(
        Rails.configuration.paths["plugins/discourse-landing-pages/app/views/discourse"]
      )
      @instance.render(*args)
    end
  end
end
