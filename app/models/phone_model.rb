class PhoneModel < ApplicationRecord
  # Associations
  has_many :devices, dependent: :restrict_with_error

  # Validations
  validates :brand, presence: true
  validates :model, presence: true
  validates :model, uniqueness: { scope: :brand }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :active, inclusion: { in: [true, false] }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_brand, ->(brand) { where(brand: brand) }

  # Instance methods
  def full_name
    "#{brand} #{model} #{storage}GB #{color}".strip
  end

  def self.available_models
    active.order(:brand, :model)
  end
end
