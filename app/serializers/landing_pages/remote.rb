class LandingPages::RemoteSerializer < ::ApplicationSerializer
  attributes :url, :branch, :private, :public_key
end