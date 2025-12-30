## User Model with Rails 8 Authentication

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :full_name, presence: true
  validates :role, presence: true, inclusion: { in: %w[admin vendedor cobrador] }

  # Optional: Add password validations
  validates :password, length: { minimum: 8 }, if: -> { new_record? || !password.nil? }

  enum role: { admin: 'admin', vendedor: 'vendedor', cobrador: 'cobrador' }

  # Rails 8 authentication uses sessions
  has_many :sessions, dependent: :destroy

  # Role helpers
  def admin?
    role == 'admin'
  end

  def vendedor?
    role == 'vendedor'
  end

  def cobrador?
    role == 'cobrador'
  end

  # Permission helpers
  def can_create_loans?
    admin? || vendedor?
  end

  def can_block_devices?
    admin? || cobrador?
  end

  def can_manage_users?
    admin?
  end

  def can_delete_records?
    admin?
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
    when 'admin'
      admin_dashboard_path
    when 'vendedor'
      vendor_customer_search_path  # Main screen for vendors
    when 'cobrador'
      cobrador_dashboard_path
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
  root "pages#home"

  # Role-specific routes
  namespace :admin do
    get 'dashboard', to: 'dashboard#index'
    # ... other admin routes
  end

  namespace :vendor do
    get 'customer_search', to: 'customer_search#index', as: :customer_search  # Main screen
    # ... other vendor routes
  end

  namespace :cobrador do
    get 'dashboard', to: 'dashboard#index'
    # ... other cobrador routes
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
      t.string :branch_number  # For vendors and cobradores
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

