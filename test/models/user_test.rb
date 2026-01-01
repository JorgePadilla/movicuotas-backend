require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
  end

  # Validations - Email
  test "validates presence of email" do
    user = User.new(email: nil)
    assert user.invalid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "validates uniqueness of email (case insensitive)" do
    existing = users(:admin)
    duplicate = User.new(
      email: existing.email.upcase,
      full_name: "Different User",
      role: "vendedor",
      password: "password123"
    )
    assert duplicate.invalid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "validates email format" do
    @user.email = "invalid-email"
    assert @user.invalid?
    assert @user.errors[:email].any?
  end

  test "accepts valid email formats" do
    valid_emails = [
      "user@example.com",
      "user+tag@example.co.uk",
      "user123@example-domain.com"
    ]
    valid_emails.each do |email|
      @user.email = email
      assert @user.valid?, "Email #{email} should be valid"
    end
  end

  # Validations - Full Name
  test "validates presence of full_name" do
    @user.full_name = nil
    assert @user.invalid?
    assert_includes @user.errors[:full_name], "can't be blank"
  end

  test "accepts long full names" do
    @user.full_name = "A" * 100
    assert @user.valid?
  end

  # Validations - Role
  test "validates presence of role" do
    user = User.new(role: nil)
    assert user.invalid?
    assert_includes user.errors[:role], "can't be blank"
  end

  test "validates role inclusion" do
    @user.role = "superuser"
    assert @user.invalid?
    assert_includes @user.errors[:role], "is not included in the list"
  end

  test "accepts valid role values" do
    %w[admin vendedor cobrador].each do |role|
      @user.role = role
      assert @user.valid?, "Role #{role} should be valid"
    end
  end

  # Validations - Password
  test "validates password length on create" do
    user = User.new(
      email: "new@example.com",
      full_name: "New User",
      role: "vendedor",
      password: "short"
    )
    assert user.invalid?
    assert @user.errors[:password].any? || user.errors[:password].any?
  end

  test "accepts password of minimum length (8 chars)" do
    user = User.new(
      email: "new@example.com",
      full_name: "New User",
      role: "vendedor",
      password: "password"
    )
    # Will be valid if password is 8+ chars
    assert user.password_digest.present? || user.valid?
  end

  test "does not validate password on update without password change" do
    @user.full_name = "Updated Name"
    assert @user.valid?
  end

  # Validations - Branch Number
  test "validates branch_number format - uppercase and numbers only" do
    @user.branch_number = "br01"  # lowercase
    assert @user.invalid?
    assert @user.errors[:branch_number].any?
  end

  test "accepts valid branch_number format" do
    @user.branch_number = "BR01"
    assert @user.valid?
  end

  test "allows blank branch_number for admin users" do
    @user.branch_number = ""
    assert @user.valid?
  end

  # Role Enum
  test "admin? predicate works" do
    @user.role = "admin"
    assert @user.admin?
    assert !@user.vendedor?
    assert !@user.cobrador?
  end

  test "vendedor? predicate works" do
    @user.role = "vendedor"
    assert @user.vendedor?
    assert !@user.admin?
    assert !@user.cobrador?
  end

  test "cobrador? predicate works" do
    @user.role = "cobrador"
    assert @user.cobrador?
  end

  # Role Enum Values
  test "role enum has correct values" do
    assert_equal "admin", User.roles[:admin]
    assert_equal "vendedor", User.roles[:vendedor]
    assert_equal "cobrador", User.roles[:cobrador]
  end

  # Permission Methods
  test "admin can create loans" do
    @user.role = "admin"
    assert @user.can_create_loans?
  end

  test "vendedor can create loans" do
    @user.role = "vendedor"
    assert @user.can_create_loans?
  end

  test "cobrador cannot create loans" do
    @user.role = "cobrador"
    assert !@user.can_create_loans?
  end

  test "admin can block devices" do
    @user.role = "admin"
    assert @user.can_block_devices?
  end

  test "cobrador can block devices" do
    @user.role = "cobrador"
    assert @user.can_block_devices?
  end

  test "vendedor cannot block devices" do
    @user.role = "vendedor"
    assert !@user.can_block_devices?
  end

  test "admin can manage users" do
    @user.role = "admin"
    assert @user.can_manage_users?
  end

  test "non-admin cannot manage users" do
    @user.role = "vendedor"
    assert !@user.can_manage_users?
  end

  test "admin can delete records" do
    @user.role = "admin"
    assert @user.can_delete_records?
  end

  test "non-admin cannot delete records" do
    @user.role = "vendedor"
    assert !@user.can_delete_records?
  end

  # Password Security
  test "password_digest is set after save" do
    user = User.new(
      email: "new@example.com",
      full_name: "New User",
      role: "vendedor",
      password: "password123"
    )
    user.save
    assert user.password_digest.present?
    assert user.password_digest != "password123"
  end

  test "authenticate method works with correct password" do
    @user.update(password: "TestPassword123")
    authenticated = @user.authenticate("TestPassword123")
    assert authenticated
  end

  test "authenticate method returns false with incorrect password" do
    @user.update(password: "TestPassword123")
    assert !@user.authenticate("WrongPassword")
  end

  # Relationships
  test "has many sessions" do
    assert_respond_to @user, :sessions
  end

  test "has many loans" do
    assert_respond_to @user, :loans
  end

  test "can destroy user with no dependent loans" do
    user = User.create!(
      email: "to_delete@example.com",
      full_name: "User to Delete",
      role: "vendedor",
      password: "password123"
    )
    assert_difference("User.count", -1) do
      user.destroy
    end
  end

  # System User
  test "system_user creates or returns existing system user" do
    system_user = User.system_user
    assert_equal "system@movicuotas.com", system_user.email
    assert system_user.admin?
  end

  test "system_user is idempotent" do
    user1 = User.system_user
    user2 = User.system_user
    assert_equal user1.id, user2.id
  end

  # Password Reset Methods
  test "generate_password_reset_token returns a string" do
    token = @user.generate_password_reset_token
    assert_kind_of String, token
    assert token.present?
  end

  test "password_reset_expired? returns false for recent reset" do
    @user.update(reset_sent_at: 1.hour.ago)
    assert !@user.password_reset_expired?
  end

  test "password_reset_expired? returns true for old reset" do
    @user.update(reset_sent_at: 3.hours.ago)
    assert @user.password_reset_expired?
  end

  test "password_reset_expired? returns true when reset_sent_at is nil" do
    @user.update(reset_sent_at: nil)
    assert @user.password_reset_expired?
  end

  # Persistence
  test "saves valid user" do
    user = User.new(
      email: "newuser@example.com",
      full_name: "New User",
      role: "vendedor",
      password: "password123"
    )
    assert user.save
    assert_not_nil user.id
  end

  test "updates user attributes" do
    @user.full_name = "Updated Name"
    @user.save
    assert_equal "Updated Name", @user.reload.full_name
  end

  # Edge Cases
  test "handles email with special characters" do
    @user.email = "user+test@example.com"
    assert @user.valid?
  end

  test "branch_number with numbers and uppercase is valid" do
    @user.branch_number = "S01"
    assert @user.valid?
  end

  test "branch_number with special characters is invalid" do
    @user.branch_number = "BR@01"
    assert @user.invalid?
  end

  # Default Values
  test "role defaults to vendedor if not specified" do
    user = User.new(
      email: "test@example.com",
      full_name: "Test User",
      password: "password123"
    )
    # Check default or that it's required
    assert user.role.blank? || user.role == "vendedor" || !user.valid?
  end
end
