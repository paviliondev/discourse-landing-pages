LandingPages::Engine.routes.draw do
  resources :page, constraints: AdminConstraint.new do
    member do
      get "export" => "page#export"
    end
    collection do
      post "import" => "page#import"
    end
  end
  post "contact" => "landing#contact"
end

Discourse::Application.routes.prepend do
  mount ::LandingPages::Engine, at: "landing"
  get "/admin/plugins/landing-pages" => "admin/plugins#index", constraints: AdminConstraint.new
  get "/:path" => "landing_pages/landing#show", constraints: LandingPageConstraint.new
end