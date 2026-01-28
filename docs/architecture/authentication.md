## User Model with Rails 8 Authentication

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :full_name, presence: true
  validates :role, presence: true, inclusion: { in: %w[master admin supervisor vendedor] }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || !password.nil? }

  # Roles:
  # - master: Full system access + loan deletion (highest privileges)
  # - admin: Full system access
  # - supervisor: Payment verification, device blocking (NOT branch-limited)
  # - vendedor: Customer registration, loan creation (branch-limited)
  enum :role, { master: "master", admin: "admin", supervisor: "supervisor", vendedor: "vendedor" }, default: "vendedor"

  # Rails 8 authentication uses sessions
  has_many :sessions, dependent: :destroy
  has_many :loans, dependent: :restrict_with_error

  # Permission helpers
  def admin_or_master?
    master? || admin?
  end

  def can_create_loans?
    admin_or_master? || vendedor?
  end

  def can_block_devices?
    admin_or_master? || supervisor?
  end

  def can_verify_payments?
    admin_or_master? || supervisor?
  end

  def can_manage_users?
    admin_or_master?
  end

  def can_delete_records?
    admin_or_master?
  end

  def can_delete_loans?
    master?
  end

  # System user for automated actions
  def self.system_user
    find_or_create_by(email: 'system@movicuotas.com') do |user|
      user.role = 'admin'
      user.full_name = 'System'
      user.password = SecureRandom.hex(32)
    end
  end
end
```

## Rails 8 Authentication Implementation

### Session Model

```ruby
# app/models/session.rb
class Session < ApplicationRecord
  belongs_to :user
end
```

### Sessions Controller (Login/Logout)

```ruby
# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  skip_before_action :authenticate, only: [:new, :create]

  def new
    # Login form
  end

  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      session = user.sessions.create!
      cookies.signed.permanent[:session_token] = { value: session.id, httponly: true }

      redirect_to after_sign_in_path_for(user), notice: "Sesión iniciada correctamente"
    else
      flash.now[:alert] = "Email o contraseña incorrectos"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    Current.session&.destroy
    cookies.delete(:session_token)
    redirect_to root_path, notice: "Sesión cerrada"
  end

  private

  def after_sign_in_path_for(user)
    case user.role
    when 'master', 'admin'
      admin_dashboard_path
    when 'supervisor'
      supervisor_dashboard_path
    when 'vendedor'
      vendor_customer_search_path  # Main screen for vendors
    else
      root_path
    end
  end
end
```

### Application Controller (Authentication)

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate

  private

  def authenticate
    if session_record = Session.find_by(id: cookies.signed[:session_token])
      Current.session = session_record
    else
      redirect_to login_path, alert: "Debes iniciar sesión"
    end
  end

  def current_user
    Current.session&.user
  end
  helper_method :current_user
end
```

### Current Context

```ruby
# app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  attribute :session

  def user
    session&.user
  end
end
```

### Authentication Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Authentication
  get  "login",  to: "sessions#new"
  post "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # Public pages
  root "home#index"

  # Role-specific routes
  namespace :admin do
    root to: "dashboard#index"
    get 'dashboard', to: 'dashboard#index'
    resources :loans, only: [:index, :show, :destroy]  # Master can delete loans
    # ... other admin routes
  end

  namespace :vendor do
    get 'customer_search', to: 'customer_search#index', as: :customer_search  # Main screen
    # ... other vendor routes
  end

  namespace :supervisor do
    get 'dashboard', to: 'dashboard#index'
    # ... other supervisor routes
  end
end
```

### Database Migrations

**Users table:**
```ruby
class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false, index: { unique: true }
      t.string :password_digest, null: false
      t.string :full_name, null: false
      t.string :role, null: false, default: 'vendedor'
      t.string :branch_number  # For vendors
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
```

**Sessions table:**
```ruby
class CreateSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end
end
```

### Default Users (Seeds)

```ruby
# db/seeds.rb

# Master user (highest privileges - can delete loans)
User.find_or_create_by!(email: 'master@movicuotas.com') do |user|
  user.full_name = 'Master Usuario'
  user.password = 'Honduras1!'
  user.role = 'master'
  user.branch_number = 'S01'
  user.active = true
end

# Admin user
User.find_or_create_by!(email: 'admin@movicuotas.com') do |user|
  user.full_name = 'Administrador Principal'
  user.password = 'password123'
  user.role = 'admin'
  user.branch_number = 'S01'
  user.active = true
end

# Supervisor user
User.find_or_create_by!(email: 'supervisor@movicuotas.com') do |user|
  user.full_name = 'Supervisor Ejemplo'
  user.password = 'password123'
  user.role = 'supervisor'
  user.branch_number = 'S01'
  user.active = true
end

# Vendedor user
User.find_or_create_by!(email: 'vendedor@movicuotas.com') do |user|
  user.full_name = 'Vendedor Ejemplo'
  user.password = 'password123'
  user.role = 'vendedor'
  user.branch_number = 'S01'
  user.active = true
end
```

### Password Reset (Optional)

If you need password reset functionality:

```ruby
# app/controllers/passwords_controller.rb
class PasswordsController < ApplicationController
  skip_before_action :authenticate

  def new
    # Request password reset
  end

  def create
    user = User.find_by(email: params[:email])

    if user
      # Generate reset token
      token = user.generate_password_reset_token
      # Send email with reset link
      PasswordMailer.reset(user, token).deliver_later
    end

    # Always show success to prevent email enumeration
    redirect_to login_path, notice: "Si el email existe, recibirás instrucciones"
  end

  def edit
    # Reset password form (with token)
  end

  def update
    # Update password with token
  end
end
```
