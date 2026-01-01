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
  root "home#index"
  get "/home", to: "pages#home", as: :home

  # Role-specific routes (placeholders for future branches)
  namespace :admin do
    get "dashboard", to: "dashboard#index"
    # ... other admin routes will be added in phase3-admin-* branches
  end

  namespace :vendor do
    get "customer_search", to: "customer_search#index", as: :customer_search  # Main screen for vendors
    get "dashboard", to: "dashboard#index"  # Dashboard accessible from navigation menu

    # Credit Application Workflow (Steps 4-9)
    resources :credit_applications, only: [ :new, :create, :show, :edit, :update ] do
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
    resource :application_recovery, only: [ :show, :create ], controller: "application_recovery"

    # Device selection (Step 10)
    resources :device_selections, only: [ :show, :update ], param: :credit_application_id
    # Confirmation (Step 11) - will be implemented in phase2-vendor-confirmation branch
    get "device_selections/:credit_application_id/confirmation", to: "device_selections#confirmation", as: :device_selection_confirmation

    # Payment Calculator (Step 12)
    resource :payment_calculator, only: [ :new, :create ] do
      post :calculate, on: :collection
    end

    # Contract routes (Steps 13-14)
    resources :contracts, only: [ :show ] do
      member do
        get :signature
        post :save_signature
        get :download
      end
    end

    # Loan finalization (Step 15) and Loan Tracking (Step 18)
    resources :loans, only: [ :new, :create, :show, :index ] do
      member do
        get :download_contract
      end
    end
    # MDM Blueprint (Step 16) - placeholder for now
    resources :mdm_blueprints, only: [ :show ], param: :id

    # Payment tracking (Step 18)
    resources :payments, only: [ :index ]

    # Reports (placeholder for future development)
    resources :reports, only: [ :index ]

    # ... other vendor routes will be added in phase2-vendor-* branches
  end

  namespace :cobrador do
    get "dashboard", to: "dashboard#index"
    # ... other cobrador routes will be added in phase4-cobrador-* branches
  end
end
