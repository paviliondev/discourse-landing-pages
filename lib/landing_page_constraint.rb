class LandingPageConstraint
  def matches?(request)
    LandingPages::Page.exists?(request.path_parameters[:path], 'path')
  end
end