class LandingPages::PageSerializer < ::ApplicationSerializer
  attributes :id, :name, :path, :theme_id, :body
end