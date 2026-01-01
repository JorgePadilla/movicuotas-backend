require "test_helper"

class DeviceTest < ActiveSupport::TestCase
  setup do
    @phone_model = phone_models(:iphone_14)
    @device = Device.new(
      phone_model: @phone_model,
      imei: "123456789012345",
      brand: "Apple",
      model: "iPhone 14",
      lock_status: "unlocked"
    )
  end

  # Validations - Phone Model
  test "validates presence of phone_model" do
    @device.phone_model = nil
    assert @device.invalid?
    assert_includes @device.errors[:phone_model], "can't be blank"
  end

  # Validations - IMEI
  test "validates presence of imei" do
    @device.imei = nil
    assert @device.invalid?
    assert_includes @device.errors[:imei], "can't be blank"
  end

  test "validates imei is exactly 15 digits" do
    @device.imei = "12345678901234"  # 14 digits
    assert @device.invalid?
    assert_includes @device.errors[:imei], "deve tener 15 dígitos"
  end

  test "validates imei contains only digits" do
    @device.imei = "12345678901234a"
    assert @device.invalid?
    assert @device.errors[:imei].any?
  end

  test "validates imei uniqueness" do
    @device.save!
    duplicate = Device.new(
      phone_model: @phone_model,
      imei: @device.imei,
      brand: "Apple",
      model: "iPhone 14",
      lock_status: "unlocked"
    )
    assert duplicate.invalid?
    assert_includes duplicate.errors[:imei], "has already been taken"
  end

  test "accepts valid 15-digit imei" do
    @device.imei = "123456789012345"
    assert @device.valid?
  end

  # Validations - Brand
  test "validates presence of brand" do
    @device.brand = nil
    assert @device.invalid?
    assert_includes @device.errors[:brand], "can't be blank"
  end

  # Validations - Model
  test "validates presence of model" do
    @device.model = nil
    assert @device.invalid?
    assert_includes @device.errors[:model], "can't be blank"
  end

  # Validations - Lock Status
  test "validates presence of lock_status" do
    @device.lock_status = nil
    assert @device.invalid?
    assert_includes @device.errors[:lock_status], "can't be blank"
  end

  test "validates lock_status inclusion" do
    @device.lock_status = "hacked"
    assert @device.invalid?
    assert_includes @device.errors[:lock_status], "is not included in the list"
  end

  test "accepts valid lock_status values" do
    %w[unlocked pending locked].each do |status|
      @device.lock_status = status
      assert @device.valid?, "Lock status #{status} should be valid"
    end
  end

  # Lock Status Enum
  test "unlocked? method works" do
    @device.lock_status = "unlocked"
    assert @device.unlocked?
    assert !@device.locked?
    assert !@device.pending?
  end

  test "pending? method works" do
    @device.lock_status = "pending"
    assert @device.pending?
    assert !@device.locked?
    assert !@device.unlocked?
  end

  test "locked? method works" do
    @device.lock_status = "locked"
    assert @device.locked?
    assert !@device.pending?
    assert !@device.unlocked?
  end

  # Scopes
  test "locked scope returns only locked devices" do
    @device.lock_status = "locked"
    @device.save!

    unlocked = Device.create!(
      phone_model: phone_models(:samsung_s24),
      imei: "234567890123456",
      brand: "Samsung",
      model: "S24",
      lock_status: "unlocked"
    )

    assert_includes Device.locked, @device
    assert_not_includes Device.locked, unlocked
  end

  test "pending_lock scope returns devices pending lock" do
    @device.lock_status = "pending"
    @device.save!

    unlocked = Device.create!(
      phone_model: phone_models(:samsung_s24),
      imei: "234567890123456",
      brand: "Samsung",
      model: "S24",
      lock_status: "unlocked"
    )

    assert_includes Device.pending_lock, @device
    assert_not_includes Device.pending_lock, unlocked
  end

  test "unlocked scope returns only unlocked devices" do
    @device.lock_status = "unlocked"
    @device.save!

    locked = Device.create!(
      phone_model: phone_models(:samsung_s24),
      imei: "234567890123456",
      brand: "Samsung",
      model: "S24",
      lock_status: "locked"
    )

    assert_includes Device.unlocked, @device
    assert_not_includes Device.unlocked, locked
  end

  # Relationships
  test "belongs to phone_model" do
    assert_respond_to @device, :phone_model
    @device.save!
    assert_equal @phone_model, @device.phone_model
  end

  test "belongs to loan (optional)" do
    assert_respond_to @device, :loan
  end

  test "can have optional locked_by user" do
    assert_respond_to @device, :locked_by
  end

  test "has one mdm_blueprint" do
    assert_respond_to @device, :mdm_blueprint
  end

  # Lock Methods
  test "lock! method transitions from unlocked to pending" do
    @device.save!
    user = users(:cobrador)

    # First call should work (unlocked -> pending)
    result = @device.lock!(user)
    @device.reload

    assert @device.pending? || @device.locked?
  end

  test "locked? returns true only when lock_status is locked" do
    @device.lock_status = "locked"
    assert @device.locked?

    @device.lock_status = "pending"
    assert !@device.locked?

    @device.lock_status = "unlocked"
    assert !@device.locked?
  end

  # Persistence
  test "saves valid device" do
    assert @device.save
    assert_not_nil @device.id
  end

  test "updates device attributes" do
    @device.save!
    @device.update(lock_status: "pending")
    assert_equal "pending", @device.reload.lock_status
  end

  # Edge Cases
  test "handles long brand names" do
    @device.brand = "A" * 100
    assert @device.valid?
  end

  test "handles long model names" do
    @device.model = "A" * 100
    assert @device.valid?
  end

  test "accepts imei with leading zeros" do
    @device.imei = "000000000000000"
    assert @device.valid?
  end

  test "accepts imei with all same digits" do
    @device.imei = "111111111111111"
    assert @device.valid?
  end

  # Default Values
  test "lock_status defaults to unlocked" do
    new_device = Device.new(
      phone_model: @phone_model,
      imei: "987654321098765",
      brand: "Apple",
      model: "iPhone 14"
    )
    assert_equal "unlocked", new_device.lock_status
  end

  # State Transitions
  test "device transitions through lock states" do
    @device.save!

    # Start: unlocked
    assert @device.unlocked?

    # Update: pending
    @device.update(lock_status: "pending")
    assert @device.pending?

    # Update: locked
    @device.update(lock_status: "locked")
    assert @device.locked?

    # Update: unlocked again
    @device.update(lock_status: "unlocked")
    assert @device.unlocked?
  end

  # Relationship Constraints
  test "device can be destroyed if not assigned to loan" do
    @device.save!
    assert_difference("Device.count", -1) do
      @device.destroy
    end
  end

  # IMEI Validation Edge Cases
  test "imei with all zeros is valid" do
    @device.imei = "000000000000000"
    assert @device.valid?
  end

  test "imei with all nines is valid" do
    @device.imei = "999999999999999"
    assert @device.valid?
  end

  test "imei with mixed digits is valid" do
    @device.imei = "492033129400730"
    assert @device.valid?
  end

  # Scoping with Multiple Conditions
  test "devices can be filtered by phone_model" do
    @device.save!

    device2 = Device.create!(
      phone_model: phone_models(:samsung_s24),
      imei: "234567890123456",
      brand: "Samsung",
      model: "S24"
    )

    iphones = Device.where(phone_model_id: @phone_model.id)
    assert_includes iphones, @device
    assert_not_includes iphones, device2
  end
end
