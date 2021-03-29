class LandingPages::InvalidAccess < StandardError; end
class LandingPages::InvalidParameters < StandardError; end

class LandingPages::LandingController < ::ActionController::Base
  prepend_view_path(Rails.root.join('plugins', 'discourse-landing-pages', 'app', 'views'))
  helper ::EmojiHelper
  helper ::ApplicationHelper
  helper LandingHelper
  include CurrentUser
  
  before_action :find_global, only: [:show]
  before_action :find_page, only: [:show]
  before_action :check_access, only: [:show]
  before_action :find_menu, only: [:show]
  before_action :find_assets, only: [:show]
  before_action :load_theme, only: [:show]

  def show
    if @page.present?
      @title = SiteSetting.title + " | #{@page.name}"
      @classes = @page.name.parameterize
      
      if @global
        @scripts = @global.scripts if @global.scripts.present?
        @header = @global.header if @global.header.present?
        @footer = @global.footer if @global.footer.present?
      end
            
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
  
  def find_global
    @global = LandingPages::Global.find
  end
  
  def find_page
    if params[:param]
      @page = LandingPages::Page.find_child_page(params[:path])
    else
      @page = LandingPages::Page.find_by("path", params[:path])
    end
    
    unless @page.present?
      raise LandingPages::InvalidParameters.new(:path)
    end
  end
  
  def find_menu
    if @page.menu.present?
      @menu = LandingPages::Menu.find_by("name", @page.menu)
    end
  end
  
  def find_assets
    if @page.assets.present?
      @page.assets.each do |asset_name|
        if asset = LandingPages::Asset.find_by("name", asset_name)
          instance_variable_set("@#{asset.name}", asset)
        end
      end
    end
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
    params.require(:email)
    params.require(:message)
    
    result = params.permit(:email, :message)
    
    unless params[:email] =~ EmailValidator.email_regex
      raise LandingPages::InvalidParameters.new(:email)
    end
    
    result
  end
end