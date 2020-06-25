class LandingPages::PageSerializer < ::ApplicationSerializer
  attributes :id, :name, :path, :theme_id, :group_ids, :body
end