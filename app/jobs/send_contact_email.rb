# frozen_string_literal: true
module Jobs
  class SendContactEmail < ::Jobs::Base
    def execute(args)
      %i[from message].each do |key|
        raise Discourse::InvalidParameters.new(key) unless args[key].present?
      end
      message = ContactMailer.contact_email(args[:from], args[:message])
      message.header["Auto-Submitted"] = nil
      message.header["X-Auto-Response-Suppress"] = nil
      Email::Sender.new(message, :contact_email).send
    end
  end
end
