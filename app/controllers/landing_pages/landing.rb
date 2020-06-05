class LandingPages::LandingController < ::ActionController::Base
  prepend_view_path(Rails.root.join('plugins', 'discourse-landing-pages', 'app', 'views'))
  helper ::ApplicationHelper
  
  before_action :find_page
  before_action :load_theme

  def show    
    if @page.present?
      @title = SiteSetting.title + " | #{@page.name}"
      @classes = @page.name
      @menu_items = LandingPages::Menu.items
      
      render :inline => @page.body, :layout => "landing"
    else
      redirect_to path("/")
    end
  end
  
  private
  
  def find_page
    @page = LandingPages::Page.find_by_path(params[:path])
  end
  
  def load_theme
    if @page.present? && @page.theme_id.present?
      @theme_ids = request.env[:resolved_theme_ids] = [@page.theme_id]
    end
  end
end