Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Authentication
  get  "login",  to: "sessions#new"
  post "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # Password reset
  resources :passwords, only: [ :new, :create, :edit, :update ]
  get "forgot-password", to: "passwords#new", as: :forgot_password
  get "reset-password/:token", to: "passwords#edit", as: :reset_password

  # Public pages
  root "pages#home"
  get "/home", to: "pages#home", as: :home

  # Role-specific routes (placeholders for future branches)
  namespace :admin do
    get "dashboard", to: "dashboard#index"
    # ... other admin routes will be added in phase3-admin-* branches
  end

  namespace :vendor do
    get "customer_search", to: "customer_search#index", as: :customer_search  # Main screen for vendors

    # Payment Calculator (Step 12)
    resource :payment_calculator, only: [ :new, :create ] do
      post :calculate, on: :collection
    end

    # Credit Application Workflow (Steps 4-9)
    resources :credit_applications, only: [:new, :create, :show, :edit, :update] do
      member do
        get :photos, as: :photos
        patch :update_photos, as: :update_photos
        get :employment, as: :employment
        patch :update_employment, as: :update_employment
        get :summary, as: :summary
        post :submit, as: :submit
        get :approved, as: :approved
        get :rejected, as: :rejected
      end
    end

    # Step 9: Application Recovery
    resource :application_recovery, only: [:show, :create], controller: 'application_recovery'
    # ... other vendor routes will be added in phase2-vendor-* branches
  end

  namespace :cobrador do
    get "dashboard", to: "dashboard#index"
    # ... other cobrador routes will be added in phase4-cobrador-* branches
  end
end
