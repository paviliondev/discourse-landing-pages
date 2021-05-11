module UserNotificationsLandingPagesExtension
  def landing_post(opts)
    @post&.is_first_post? && landing_page && landing_email_notification_type?
  end

  def landing_page
    @landing_page ||= LandingPages::Page.find(@post.topic&.category&.landing_page_id)
  end

  def landing_email_notification_type?
    %w(
     watching
     watching_first_post
    ).include?(@notification_type)
  end

  protected def send_notification_email(opts)
    @user = opts[:user]
    @post = opts[:post]
    @notification_type = opts[:notification_type]
    super(opts)
  end

  def build_email(*builder_args)
    opts = builder_args[1]
    builder_args[1][:html_override] = landing_email_html if landing_post(opts)
    super(*builder_args)
  end

  def landing_email_html
    return landing_page.email_html if landing_page.email_html.present?

    @instance ||= UserNotificationRenderer.with_view_paths(
      Rails.configuration.paths["plugins/discourse-landing-pages/app/views/discourse"]
    )
    @instance.render(
      template: 'email/landing',
      format: :html,
      locals: {
        post: @post,
        classes: Rtl.new(@user).css_class 
      }
    )
  end
end