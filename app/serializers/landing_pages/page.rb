class LandingPages::PageSerializer < ::LandingPages::BasicPageSerializer
  attributes :parent_id,
             :theme_id,
             :group_ids,
             :body,
             :remote,
             :menu
  
  def remote
    object.remote.present?
  end
end