class AuditLog < ApplicationRecord
  # Associations
  belongs_to :user

  # Validations
  validates :action, presence: true
  validates :resource_type, presence: true
  validates :resource_id, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc).limit(100) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_resource, ->(resource) { where(resource_type: resource.class.name, resource_id: resource.id) }
  scope :by_action, ->(action) { where(action: action) }
  scope :by_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }

  # Methods
  def resource
    resource_type.constantize.find_by(id: resource_id)
  end

  def self.log(user, action, resource, changes = {})
    create!(
      user: user,
      action: action,
      resource_type: resource.class.name,
      resource_id: resource.id,
      change_details: changes,
      ip_address: user.try(:current_ip_address),
      user_agent: user.try(:current_user_agent)
    )
  end

  def self.log_system(action, resource, changes = {})
    log(User.system_user, action, resource, changes)
  end
end
