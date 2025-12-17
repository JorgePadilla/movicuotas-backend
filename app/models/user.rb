class User < ApplicationRecord
  has_secure_password

  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :full_name, presence: true
  validates :role, presence: true, inclusion: { in: %w[admin vendedor cobrador] }
  validates :branch_number, format: { with: /\A[A-Z0-9]+\z/, message: "solo letras mayúsculas y números" }, allow_blank: true

  # Optional: Add password validations
  validates :password, length: { minimum: 8 }, if: -> { new_record? || !password.nil? }

  enum :role, { admin: "admin", vendedor: "vendedor", cobrador: "cobrador" }

  # Rails 8 authentication uses sessions
  has_many :sessions, dependent: :destroy

  # Role helpers
  def admin?
    role == "admin"
  end

  def vendedor?
    role == "vendedor"
  end

  def cobrador?
    role == "cobrador"
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
    find_or_create_by(email: "system@movicuotas.com") do |user|
      user.role = "admin"
      user.full_name = "System"
      user.password = SecureRandom.hex(32)
    end
  end
end
