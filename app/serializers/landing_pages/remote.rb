# frozen_string_literal: true
class LandingPages::RemoteSerializer < ::ApplicationSerializer
  attributes :url, :branch, :private, :public_key, :connected, :commit
end
