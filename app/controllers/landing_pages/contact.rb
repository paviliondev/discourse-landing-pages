class LandingPages::ContactController < ::ApplicationController
  skip_before_action :check_xhr, :preload_json, :verify_authenticity_token
  
  def send_contact_email
    opts = params.permit(:name, :email, :message)
    
    Jobs.enqueue(:send_contact_email,
      from: opts[:email],
      message: opts[:message]
    )
    
    flash.now[:notice] = I18n.t('landing_pages.contact.sent')
    
    respond_to do |format|
      byebug
      format.json { render json: nil }
    end
  end
end