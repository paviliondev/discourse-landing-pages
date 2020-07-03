class LandingPages::InvalidAccess < StandardError; end

class LandingPages::LandingController < ::ActionController::Base
  prepend_view_path(Rails.root.join('plugins', 'discourse-landing-pages', 'app', 'views'))
  helper ::ApplicationHelper
  include CurrentUser
  
  before_action :find_page
  before_action :load_theme
  before_action :check_access

  def show    
    if @page.present?
      @title = SiteSetting.title + " | #{@page.name}"
      @classes = @page.name.parameterize
      @menu_items = LandingPages::Menu.items
            
      render :inline => @page.body, :layout => "landing"
    else
      redirect_to path("/")
    end
  end
  
  def contact    
    Jobs.enqueue(:send_contact_email,
      from: contact_params[:email],
      message: contact_params[:message]
    )        
    respond_to do |format|
      format.html
      format.js { head :ok }
    end
  end
  
  rescue_from LandingPages::InvalidAccess do |e|
    @group = Group.find(@page.group_ids.first)
    @title = I18n.t("page_forbidden.title")
    @classes = "forbidden"
    render status: 403, layout: 'landing', formats: [:html], template: '/exceptions/not_found'
  end
  
  private
  
  def find_page
    @page = LandingPages::Page.find_by_path(params[:path])
  end
  
  def check_access
    unless @page.group_ids.blank? ||
      @page.group_ids.include?(Group::AUTO_GROUPS[:everyone]) ||
      (current_user && (current_user.groups.map(&:id) && @page.group_ids).length)
      
      raise LandingPages::InvalidAccess.new
    end
  end
  
  def load_theme
    if @page.present? && @page.theme_id.present?
      @theme_ids = request.env[:resolved_theme_ids] = [@page.theme_id]
    end
  end
  
  def contact_params
    params.permit(:name, :email, :message)
  end
end