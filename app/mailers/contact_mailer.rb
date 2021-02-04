class ContactMailer < ::ActionMailer::Base
  include Email::BuildEmailHelper

  def contact_email(from, message)
    contact_email = SiteSetting.landing_contact_email || SiteSetting.contact_email
    build_email(
      contact_email,
      template: 'contact_mailer',
      locale: 'en',
      from: from,
      message: message,
      use_from_address_for_reply_to: true
    )
  end
end