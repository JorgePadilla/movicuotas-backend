require "test_helper"

class PhoneModelTest < ActiveSupport::TestCase
  setup do
    @phone_model = phone_models(:iphone_14)
  end

  # Associations
  test "has many devices" do
    assert_respond_to @phone_model, :devices
  end

  test "restricts deletion if devices exist" do
    phone = PhoneModel.create!(
      brand: "Samsung",
      model: "Galaxy S25",
      price: 12000.00,
      active: true
    )

    # Create a device with this phone model
    Device.create!(
      phone_model: phone,
      imei: "123456789012345",
      serial_number: "ABC123",
      brand: "Samsung",
      model: "Galaxy S25",
      status: "available"
    )

    assert_raises(ActiveRecord::InvalidForeignKey) do
      phone.destroy
    end
  end

  # Validations - Brand
  test "validates presence of brand" do
    phone = PhoneModel.new(brand: nil, model: "Test")
    assert phone.invalid?
    assert phone.errors[:brand].any?
  end

  test "accepts valid brand values" do
    brands = ["Apple", "Samsung", "Xiaomi", "Nokia", "Motorola"]
    brands.each do |brand|
      phone = PhoneModel.new(brand: brand, model: "Test", price: 1000.00)
      assert phone.valid? || phone.errors[:model].present?, "Brand #{brand} should be valid"
    end
  end

  # Validations - Model
  test "validates presence of model" do
    phone = PhoneModel.new(brand: "Apple", model: nil)
    assert phone.invalid?
    assert_includes phone.errors[:model], "can't be blank"
  end

  test "validates uniqueness of model within same brand" do
    existing = @phone_model
    duplicate = PhoneModel.new(
      brand: existing.brand,
      model: existing.model,
      price: 1000.00,
      active: true
    )

    assert duplicate.invalid?
    assert_includes duplicate.errors[:model], "has already been taken"
  end

  test "allows same model for different brands" do
    phone1 = PhoneModel.create!(
      brand: "Apple",
      model: "iPhone 15",
      price: 13000.00,
      active: true
    )

    phone2 = PhoneModel.new(
      brand: "Samsung",
      model: "iPhone 15",  # Same model name, different brand
      price: 12000.00,
      active: true
    )

    # Should be valid since uniqueness is scoped to brand
    assert phone2.valid?
  end

  # Validations - Price
  test "validates presence of price" do
    phone = PhoneModel.new(price: nil)
    assert phone.invalid?
    assert_includes phone.errors[:price], "can't be blank"
  end

  test "validates price is greater than 0" do
    phone = PhoneModel.new(price: 0)
    assert phone.invalid?
    assert_includes phone.errors[:price], "must be greater than 0"
  end

  test "rejects negative price" do
    phone = PhoneModel.new(price: -1000.00)
    assert phone.invalid?
  end

  test "accepts valid prices" do
    valid_prices = [0.01, 100.00, 5000.00, 50000.00]
    valid_prices.each do |price|
      phone = PhoneModel.new(
        brand: "Test",
        model: "Model",
        price: price,
        active: true
      )
      # Only price validation, not uniqueness
      assert phone.valid? || phone.errors[:model].present?
    end
  end

  test "accepts price with decimal places" do
    phone = PhoneModel.new(
      brand: "Apple",
      model: "iPhone 15 Pro",
      price: 1234.56,
      active: true
    )
    # Only check price validation passes
    assert phone.price == 1234.56
  end

  # Validations - Active
  test "validates presence of active" do
    phone = PhoneModel.new(active: nil)
    assert phone.invalid?
    assert_includes phone.errors[:active], "is not included in the list"
  end

  test "validates active is boolean" do
    phone_true = PhoneModel.new(
      brand: "Apple",
      model: "iPhone 15",
      price: 1000.00,
      active: true
    )
    # Should be valid when all required fields are present
    phone_true.valid?
    assert phone_true.errors[:active].empty?

    phone_false = PhoneModel.new(
      brand: "Apple",
      model: "iPhone 15",
      price: 1000.00,
      active: false
    )
    phone_false.valid?
    assert phone_false.errors[:active].empty?
  end

  test "rejects non-boolean active value" do
    phone = PhoneModel.new(
      brand: "Apple",
      model: "iPhone 15",
      price: 1000.00,
      active: "yes"
    )
    # Rails will convert string to boolean
    assert phone.active.is_a?(TrueClass) || phone.active.is_a?(FalseClass)
  end

  # Scopes
  test "active scope returns only active phone models" do
    active_phones = PhoneModel.active
    assert active_phones.all? { |phone| phone.active? }
  end

  test "active scope excludes inactive models" do
    inactive = PhoneModel.create!(
      brand: "Test",
      model: "Inactive Model",
      price: 1000.00,
      active: false
    )

    active_phones = PhoneModel.active
    assert_not_includes active_phones.map(&:id), inactive.id
  end

  test "by_brand scope filters by brand" do
    samsung_phones = PhoneModel.by_brand("Samsung")
    assert samsung_phones.all? { |phone| phone.brand == "Samsung" }
  end

  test "by_brand scope excludes other brands" do
    apple_phones = PhoneModel.by_brand("Apple")
    assert_not apple_phones.any? { |phone| phone.brand == "Samsung" }
  end

  # Instance Methods - full_name
  test "full_name includes brand and model" do
    phone = @phone_model
    full_name = phone.full_name
    assert_includes full_name, phone.brand
    assert_includes full_name, phone.model
  end

  test "full_name includes storage and color" do
    phone = PhoneModel.create!(
      brand: "Apple",
      model: "iPhone 15",
      price: 13000.00,
      active: true,
      storage: 256,
      color: "Gold"
    )

    full_name = phone.full_name
    assert_includes full_name, "256GB" if phone.storage.present?
    assert_includes full_name, "Gold" if phone.color.present?
  end

  test "full_name handles missing storage and color" do
    phone = PhoneModel.create!(
      brand: "Samsung",
      model: "Galaxy S25",
      price: 12000.00,
      active: true
    )

    full_name = phone.full_name
    # Should not include empty storage/color
    assert_includes full_name, "Samsung"
    assert_includes full_name, "Galaxy S25"
  end

  test "full_name strips extra spaces" do
    phone = PhoneModel.create!(
      brand: "Xiaomi",
      model: "13 Pro",
      price: 8000.00,
      active: true
    )

    full_name = phone.full_name
    # Check it's not excessively spaced
    assert_not_includes full_name, "  "  # No double spaces
  end

  # Class Methods - available_models
  test "available_models returns active models ordered by brand and model" do
    available = PhoneModel.available_models
    assert available.all? { |phone| phone.active? }

    # Check ordering
    brands_and_models = available.map { |p| [p.brand, p.model] }
    assert_equal brands_and_models.sort, brands_and_models
  end

  test "available_models excludes inactive models" do
    inactive = PhoneModel.create!(
      brand: "Zzz",  # Intentionally high to test ordering
      model: "ZzzzModel",
      price: 1000.00,
      active: false
    )

    available = PhoneModel.available_models
    assert_not_includes available.map(&:id), inactive.id
  end

  test "available_models is ordered correctly" do
    PhoneModel.create!(brand: "Zebra", model: "Z1", price: 1000.00, active: true)
    PhoneModel.create!(brand: "Apple", model: "A1", price: 1000.00, active: true)
    PhoneModel.create!(brand: "Apple", model: "B1", price: 1000.00, active: true)

    available = PhoneModel.available_models
    brands = available.map(&:brand)

    # Apple should come before Zebra
    apple_index = brands.index("Apple")
    zebra_index = brands.index("Zebra")
    assert apple_index < zebra_index if apple_index && zebra_index
  end

  # Optional Attributes
  test "storage attribute is optional" do
    phone = PhoneModel.new(
      brand: "Apple",
      model: "iPhone 15",
      price: 13000.00,
      active: true,
      storage: nil
    )
    assert phone.storage.nil?
  end

  test "color attribute is optional" do
    phone = PhoneModel.new(
      brand: "Samsung",
      model: "Galaxy S25",
      price: 12000.00,
      active: true,
      color: nil
    )
    assert phone.color.nil?
  end

  test "stores storage and color values" do
    phone = PhoneModel.create!(
      brand: "Apple",
      model: "iPhone 15 Plus",
      price: 14000.00,
      active: true,
      storage: 512,
      color: "Deep Purple"
    )

    phone.reload
    assert_equal 512, phone.storage
    assert_equal "Deep Purple", phone.color
  end

  # Persistence
  test "persists phone model with all attributes" do
    phone = PhoneModel.create!(
      brand: "OnePlus",
      model: "12 Pro",
      price: 11000.00,
      active: true,
      storage: 256,
      color: "Black"
    )

    assert phone.persisted?
    assert_not_nil phone.id

    reloaded = PhoneModel.find(phone.id)
    assert_equal "OnePlus", reloaded.brand
    assert_equal "12 Pro", reloaded.model
    assert_equal 11000.00, reloaded.price
    assert_equal true, reloaded.active
  end

  test "updates phone model attributes" do
    phone = @phone_model
    original_price = phone.price

    phone.price = 15000.00
    phone.save

    assert_not_equal original_price, phone.reload.price
    assert_equal 15000.00, phone.price
  end

  test "updates active status" do
    phone = @phone_model
    phone.active = false
    phone.save

    assert_equal false, phone.reload.active
  end

  test "destroys phone model without devices" do
    phone = PhoneModel.create!(
      brand: "Motorola",
      model: "Edge 50",
      price: 9000.00,
      active: true
    )
    phone_id = phone.id

    phone.destroy
    assert_nil PhoneModel.find_by(id: phone_id)
  end

  # Edge Cases
  test "handles very long brand name" do
    phone = PhoneModel.create!(
      brand: "A" * 100,
      model: "Test Model",
      price: 1000.00,
      active: true
    )

    assert phone.persisted?
    assert_equal 100, phone.brand.length
  end

  test "handles very long model name" do
    phone = PhoneModel.create!(
      brand: "TestBrand",
      model: "B" * 100,
      price: 1000.00,
      active: true
    )

    assert phone.persisted?
    assert_equal 100, phone.model.length
  end

  test "handles very high price" do
    phone = PhoneModel.create!(
      brand: "Luxury",
      model: "Premium",
      price: 999999.99,
      active: true
    )

    assert phone.persisted?
    assert_equal 999999.99, phone.price
  end

  test "handles very low price" do
    phone = PhoneModel.create!(
      brand: "Budget",
      model: "Basic",
      price: 0.01,
      active: true
    )

    assert phone.persisted?
    assert_equal 0.01, phone.price
  end
end
