module Jobs
  class SendContactEmail < ::Jobs::Base
    def execute(args)
      [
        :from,
        :message
      ].each do |key|
        raise Discourse::InvalidParameters.new(key) unless args[key].present?
      end
      message = ContactMailer.contact_email(args[:from], args[:message])
      Email::Sender.new(message, :contact_email).send
    end
  end
end