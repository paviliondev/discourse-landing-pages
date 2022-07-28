# frozen_string_literal: true
class LandingPages::BasicPageSerializer < ::ApplicationSerializer
  attributes :id,
             :name,
             :path
end
