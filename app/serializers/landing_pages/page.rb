# frozen_string_literal: true
class LandingPages::PageSerializer < ::LandingPages::BasicPageSerializer
  attributes :parent_id, :category_id, :theme_id, :group_ids, :body, :remote, :menu

  def remote
    object.remote.present?
  end
end
