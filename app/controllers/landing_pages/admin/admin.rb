# frozen_string_literal: true
class LandingPages::AdminController < ::Admin::AdminController

  private

  def check_page_exists
    unless LandingPages::Page.exists?(params[:id])
      raise Discourse::InvalidParameters.new(:id)
    end
  end

  def find_page
    @page = LandingPages::Page.find(params[:id])
  end

  def serialzed_pages
    ActiveModel::ArraySerializer.new(
      LandingPages::Page.all,
      each_serializer: LandingPages::BasicPageSerializer,
      root: false
    )
  end

  def serialize_page(page)
    LandingPages::PageSerializer.new(page, root: false)
  end

  def serialize_menus
    ActiveModel::ArraySerializer.new(
      LandingPages::Menu.all,
      each_serializer: LandingPages::MenuSerializer,
      root: false
    )
  end

  def serialized_remote
    LandingPages::RemoteSerializer.new(LandingPages::Remote.get, root: false)
  end

  def serialized_global
    LandingPages::GlobalSerializer.new(LandingPages::Global.find, root: false)
  end

  def render_page(page, include_pages: false)
    if page.valid?
      json = {
        page: serialize_page(page)
      }
      json[:pages] = serialzed_pages if include_pages
      render_json_dump(json)
    else
      render_json_error(page)
    end
  end
end
