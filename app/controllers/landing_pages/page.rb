class LandingPages::PageController < ::Admin::AdminController
  skip_before_action :check_xhr, only: [:export]
  before_action :check_page_exists, only: [:show, :update, :destroy, :export]
  before_action :find_page, only: [:show, :update, :export]
  
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
  
  def destroy
    if LandingPages::Page.destroy(params[:page_id])
      render json: success_json.merge(pages: serialzed_pages)
    else
      render json: failed_json
    end
  end
  
  def export
    exporter = LandingPages::PageExporter.new(@page)
    file_path = exporter.package_filename
    
    headers['Content-Length'] = File.size(file_path).to_s
    send_data File.read(file_path),
      filename: File.basename(file_path),
      content_type: "application/zip"
  ensure
    exporter.cleanup!
  end
  
  def import
    page = params[:page]
    importer = LandingPages::PageImporter.new(
      page.tempfile.path,
      page.original_filename
    )
    
    importer.unzip!
    
    begin
      meta = JSON.parse(importer["meta.json"])
    rescue TypeError, JSON::ParserError
      raise LandingPages::ImportError.new
    end
    
    page = LandingPages::Page.find(meta['id'])
    
    if page.blank?
      if LandingPages::Page.find_by_path(meta['path'])
        raise LandingPages::ImportError.new, I18n.t("themes.import_error.path_exists", path: meta['path'])
      end
      
      page = LandingPages::Page.create(meta)
    end

    page.body = importer["body.html.erb"]
    page.save
    
    handle_render(page)
  ensure
    importer.cleanup!
  end
  
  private
  
  def check_page_exists
    unless LandingPages::Page.exists?(params[:id])
      raise Discourse::InvalidParameters.new(:id)
    end
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
        pages: serialzed_pages
      )
    else
      render_json_error(page)
    end
  end
  
  def serialzed_pages
    ActiveModel::ArraySerializer.new(
      LandingPages::Page.all,
      each_serializer: LandingPages::PageSerializer,
      root: false
    )
  end
end