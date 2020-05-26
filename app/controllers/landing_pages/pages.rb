class LandingPages::PageController < ::Admin::AdminController
  before_action :check_page_exists, only: [:show, :update]
  before_action :find_page, only: [:show, :update]
  
  def index
    render_serialized(LandingPages::Page.all, LandingPages::PageSerializer, root: 'pages')
  end

  def show
    render_serialized(@page, LandingPages::PageSerializer, root: false)
  end

  def update
    @page.set(page_params)
    @page.save
    handle_render(@page)
  end

  def create
    handle_render(LandingPages::Page.create(page_params))
  end
  
  private
  
  def check_page_exists
    LandingPages::Page.exists?(params[:id])
  end

  def find_page
    @page = LandingPages::Page.find(params[:id])
  end
  
  def page_params
    params.require(:page)
      .permit(
        :name,
        :path,
        :theme_id,
        :body
      ).to_h
  end
  
  def handle_render(page)
    if page.valid?
      render json: success_json.merge(
        page: LandingPages::PageSerializer.new(page, root: false),
        pages: ActiveModel::ArraySerializer.new(
          LandingPages::Page.all,
          each_serializer: LandingPages::PageSerializer,
          root: false
        )
      )
    else
      render_json_error(page)
    end
  end
end