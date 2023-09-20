# frozen_string_literal: true
LandingPages::Engine.routes.draw do
  resources :page, constraints: AdminConstraint.new do
    member { get "export" => "page#export" }
    collection { post "upload" => "page#upload" }
  end

  resource :remote, constraints: AdminConstraint.new do
    collection do
      get "pages" => "remotes#import"
      post "test" => "remotes#test"
      get "commits-behind" => "remotes#commits_behind"
    end
  end

  resource :global, constraints: AdminConstraint.new

  post "contact" => "landing#contact"
  post "subscription" => "landing#subscription"
  get "topic-list" => "landing#topic_list"
end

Discourse::Application.routes.prepend do
  mount ::LandingPages::Engine, at: "landing"
  get "/admin/plugins/landing-pages" => "admin/plugins#index", :constraints => AdminConstraint.new
  get "/:path" => "landing_pages/landing#show", :constraints => LandingPageConstraint.new
  get "/:path/:param" => "landing_pages/landing#show", :constraints => LandingPageConstraint.new
end
