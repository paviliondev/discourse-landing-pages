LandingPages::Engine.routes.draw do
  resources :page, constraints: AdminConstraint.new
  post "contact" => "contact#send_contact_email"
end

Discourse::Application.routes.prepend do
  mount ::LandingPages::Engine, at: 'landing'
  get '/admin/plugins/landing-pages' => 'admin/plugins#index', constraints: AdminConstraint.new
  get "/:path" => 'landing_pages/landing#show', constraints: LandingPageConstraint.new
end