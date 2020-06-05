class ContactMailer < ::ActionMailer::Base
  include Email::BuildEmailHelper

  def contact_email(from, message)
    build_email(
      SiteSetting.landing_contact_email,
      template: 'contact_mailer',
      locale: 'en',
      from: from,
      message: message
    )
  end
end