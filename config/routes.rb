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
    root to: "dashboard#index"
    get "dashboard", to: "dashboard#index", as: :dashboard

    # Admin management routes (Phase 3)
    resources :users  # User management
    resources :customers  # Customer management
    resources :loans, only: [:index, :show]  # Loan management (view only)
    resources :payments do  # Payment management (Admin/Supervisor: full CRUD, Vendedor: view only)
      member do
        post :verify
        post :reject
      end
    end
    resources :installments, only: [] do  # Installment management (Admin/Supervisor only)
      member do
        post :mark_paid
      end
    end
    resources :audit_logs, only: [:index, :show]  # Audit log viewing (Admin only)
    resources :contracts, only: [:index, :show]  # Contract management (QR handled by default_qr_codes)
    resources :default_qr_codes, only: [:index, :edit, :update] do  # Default QR code for all contracts
      member do
        get :download
      end
    end
    resources :reports, only: [:index] do  # Reports & analytics
      collection do
        get :branch_analytics
        get :revenue_report
        get :customer_portfolio
        get :export_report
      end
    end
    resources :jobs, only: [:index, :show] do  # Background job monitoring (Phase 5)
      collection do
        post :trigger
      end
      member do
        post :retry
        post :cancel
      end
    end

    # Down payment verification (admin verifies deposit receipts)
    resources :down_payments, only: [:index, :show] do
      member do
        post :verify
        post :reject
      end
    end
  end

  namespace :vendor do
    root to: "customer_search#index"  # Main screen after login
    get "customer_search", to: "customer_search#index", as: :customer_search  # Main screen for vendors
    get "dashboard", to: "dashboard#index", as: :dashboard

    # Contract routes (Steps 13-14)
    resources :contracts, only: [:show] do
      member do
        get :signature
        post :save_signature
        get :download
        get :success  # Step 15: Success confirmation after signature
      end
      # Down payment collection (Step 14.5: between signature and success)
      resource :down_payment, only: [:show, :update], controller: "down_payments"
    end

    # Device selection (Step 10)
    resources :device_selections, only: [:show, :update], param: :credit_application_id
    # Confirmation (Step 11) - will be implemented in phase2-vendor-confirmation branch
    get "device_selections/:credit_application_id/confirmation", to: "device_selections#confirmation", as: :device_selection_confirmation

    # Payment Calculator (Step 12)
    resource :payment_calculator, only: [ :new, :create ] do
      post :calculate, on: :collection
    end

    # Credit Application Workflow (Steps 4-9)
    resources :credit_applications, only: [ :new, :create, :show, :edit, :update ] do
      member do
        get :photos, as: :photos
        patch :update_photos, as: :update_photos
        get :verify_otp, as: :verify_otp                      # OTP verification page
        post :send_otp, as: :send_otp                         # Send OTP (after method selection)
        post :submit_otp_verification, as: :submit_otp        # Submit OTP code
        post :resend_otp, as: :resend_otp                     # Resend OTP code
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

    # Loan finalization (Step 15)
    resources :loans, only: [ :new, :create, :show, :index ] do
      member do
        get :download_contract
      end
    end
    # MDM Blueprint (Step 16) and Checklist (Step 17)
    resources :mdm_blueprints, only: [ :show ], param: :id do
      resource :mdm_checklist, only: [ :show, :create ]
    end
    # Payment tracking (Step 18)
    resources :payments, only: [ :index ]

    # ... other vendor routes will be added in phase2-vendor-* branches
  end

  # Supervisor namespace - for payment verification, device blocking, collection reports
  namespace :supervisor do
    get "dashboard", to: "dashboard#index"
    resources :overdue_devices, only: [:index, :show] do
      member do
        get :block
        post :confirm_block
      end
    end
    get "bulk-operations", to: "bulk_operations#show", as: "bulk_operations"
    post "bulk-operations/confirm", to: "bulk_operations#confirm_bulk_block", as: "confirm_bulk_operations"
    get "loans/:loan_id/payment-history", to: "payment_history#show", as: "loan_payment_history"
    get "collection-reports", to: "collection_reports#index", as: "collection_reports"
  end

  # Mobile API (Phase 6)
  namespace :api do
    namespace :v1 do
      # Authentication
      post "auth/login", to: "auth#login"
      get "auth/forgot_contract", to: "auth#forgot_contract"

      # Customer endpoints
      get "dashboard", to: "dashboard#show"
      get "installments", to: "installments#index"
      post "payments", to: "payments#create"
      get "notifications", to: "notifications#index"
    end
  end
end