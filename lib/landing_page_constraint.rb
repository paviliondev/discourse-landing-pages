# frozen_string_literal: true

class LandingPageConstraint
  def matches?(request)
    LandingPages::Page.exists?(request.path_parameters[:path], attr: 'path')
  end
end
