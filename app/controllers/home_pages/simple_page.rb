# frozen_string_literal: true

module ::DiscourseHomePages
  class SimplePageController < ::ApplicationController
    # requires_plugin ::DiscourseHomePages::PLUGIN_NAME
    before_action :ensure_plugin_enabled

    def index
      render json: success_json
    end

    private

    def ensure_plugin_enabled

      unless SiteSetting.home_pages_enabled
        redirect_to path("/")
      end
    end
  end
end
