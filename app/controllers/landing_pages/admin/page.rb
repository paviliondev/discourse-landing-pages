# frozen_string_literal: true

class LandingPages::PageController < LandingPages::AdminController
  skip_before_action :check_xhr, only: [:export]
  
  before_action :refresh_remote, only: [:index]
  before_action :check_page_exists, only: [:show, :update, :destroy, :export]
  before_action :find_page, only: [:show, :update, :export]
  
  def index
    render_json_dump(
      pages: serialzed_pages,
      menus: serialize_menus,
      remote: serialized_remote,
      global: serialized_global
    )
  end

  def show
    render_page(@page)
  end

  def update
    @page.set(page_params)
    @page.save
    render_page(@page, include_pages: true)
  end

  def create
    render_page(LandingPages::Page.create(page_params), include_pages: true)
  end
  
  def destroy
    if LandingPages::Page.destroy(params[:id])
      render json: success_json.merge(pages: serialzed_pages)
    else
      render json: failed_json
    end
  end
  
  def export
    exporter = LandingPages::ZipExporter.new(@page)
    file_path = exporter.package_filename
    
    headers['Content-Length'] = File.size(file_path).to_s
    send_data File.read(file_path),
      filename: File.basename(file_path),
      content_type: "application/zip"
  ensure
    exporter.cleanup!
  end
  
  def upload
    importer = LandingPages::Importer.new(:zip, bundle: params[:page])
    importer.perform!
    
    if importer.report[:errors].any?
      render json: failed_json.merge(errors: importer.report[:errors])
    else
      render json: success_json.merge(page: serialize_page(page))
    end
  end
  
  private
  
  def page_params
    params.require(:page)
      .permit(
        :name,
        :path,
        :parent_id,
        :theme_id,
        :body,
        :menu,
        group_ids: []
      ).to_h
  end
  
  def refresh_remote
    if remote = LandingPages::Remote.get
      remote.reset
    end
  end
end