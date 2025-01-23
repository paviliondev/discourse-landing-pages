# frozen_string_literal: true

class LandingPages::RemotesController < LandingPages::AdminController
  requires_plugin LandingPages::PLUGIN_NAME

  def update
    remote = LandingPages::Remote.update(remote_params)

    if remote.valid?
      render json:
               success_json.merge(remote: LandingPages::RemoteSerializer.new(remote, root: false))
    else
      render_json_error(remote)
    end
  end

  def destroy
    if LandingPages::Remote.destroy
      render json: success_json.merge(pages: serialzed_pages)
    else
      render json: failed_json
    end
  end

  def import
    importer = LandingPages::Importer.new(:git)
    importer.perform!

    render_json_dump(
      report: importer.report,
      menus: serialize_menus,
      pages: serialzed_pages,
      global: serialized_global,
    )
  end

  def test
    remote = LandingPages::Remote.new(remote_params)

    if remote.connected
      render json: success_json
    else
      render json: failed_json
    end
  end

  def commits_behind
    remote = LandingPages::Remote.get

    if remote.connected
      remote.reset

      render json: { commits_behind: remote.commits_behind }
    else
      render json: failed_json
    end
  end

  private

  def remote_params
    params.require(:remote).permit(:url, :branch, :public_key, :private_key)
  end
end
