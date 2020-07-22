class LandingPages::PageSerializer < ::ApplicationSerializer
  attributes :id,
             :name,
             :path,
             :theme_id,
             :group_ids,
             :body,
             :remote,
             :menu
  
  def remote
    object.remote.present?
  end
end