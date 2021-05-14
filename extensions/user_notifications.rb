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
    builder_args[1][:html_override] = landing_email_html(opts) if landing_post(opts)
    super(*builder_args)
  end

  def landing_email_html(opts)
    return landing_page.email if landing_page.email.present?

    unstyled = LandingEmailRenderer.render(
      template: 'email/landing',
      format: :html,
      locals: {
        post: @post
      }
    )
    style = Email::Styles.new(unstyled, opts)

    style.format_basic
    style.format_html
    style.to_html
  end
end