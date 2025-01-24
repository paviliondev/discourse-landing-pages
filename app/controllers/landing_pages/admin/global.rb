# frozen_string_literal: true

class LandingPages::GlobalsController < LandingPages::AdminController
  requires_plugin LandingPages::PLUGIN_NAME

  def update
    global = LandingPages::Global.new(global_params.to_h)

    if global.save
      render json: success_json
    else
      render json: error_json
    end
  end

  def destroy
    if LandingPages::Global.destroy
      render json: success_json
    else
      render json: error_json
    end
  end

  protected

  def global_params
    params.require(:global).permit(scripts: [], header: {}, footer: {})
  end
end
