require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  setup do
    @notification = notifications(:notification_one)
    @customer = customers(:customer_one)
  end

  # Associations
  test "belongs to customer" do
    assert_respond_to @notification, :customer
    assert @notification.customer.present?
  end

  # Validations
  test "validates presence of title" do
    notification = Notification.new(title: nil)
    assert notification.invalid?
    assert_includes notification.errors[:title], "can't be blank"
  end

  test "validates presence of body" do
    notification = Notification.new(body: nil)
    assert notification.invalid?
    assert_includes notification.errors[:body], "can't be blank"
  end

  test "validates presence of notification_type" do
    notification = Notification.new(notification_type: nil)
    assert notification.invalid?
    assert_includes notification.errors[:notification_type], "can't be blank"
  end

  test "validates notification_type inclusion" do
    notification = Notification.new(notification_type: "invalid_type")
    assert notification.invalid?
    assert_includes notification.errors[:notification_type], "is not included in the list"
  end

  test "accepts valid notification_type values" do
    valid_types = %w[payment_reminder device_lock payment_confirmation general]
    valid_types.each do |type|
      notification = Notification.new(
        customer: @customer,
        title: "Test",
        body: "Test body",
        notification_type: type
      )
      assert notification.valid?, "Type #{type} should be valid"
    end
  end

  # Enums
  test "notification_type enum works correctly" do
    notification = Notification.new(notification_type: "payment_reminder")
    assert notification.notification_type_payment_reminder?
  end

  test "all notification_type predicates work" do
    types = Notification.notification_types.keys
    types.each do |type|
      notification = Notification.new(notification_type: type)
      predicate = "notification_type_#{type}?"
      assert notification.send(predicate), "#{predicate} should return true"
    end
  end

  test "defaults to general notification_type" do
    notification = Notification.new(customer: @customer, title: "Test", body: "Body")
    assert_equal "general", notification.notification_type
  end

  # Scopes
  test "unread scope returns notifications without read_at" do
    unread = Notification.unread
    assert unread.all? { |n| n.read_at.nil? }
  end

  test "read scope returns notifications with read_at" do
    read = Notification.read
    assert read.all? { |n| n.read_at.present? }
  end

  test "recent scope returns 50 most recent notifications" do
    recent = Notification.recent
    assert recent.count <= 50

    # Check ordering - should be newest first
    if recent.count > 1
      assert recent.first.created_at >= recent.second.created_at
    end
  end

  test "by_type scope filters by notification_type" do
    payment_reminders = Notification.by_type("payment_reminder")
    assert payment_reminders.all? { |n| n.notification_type == "payment_reminder" }
  end

  test "by_customer scope filters by customer" do
    customer_notifications = Notification.by_customer(@customer)
    assert customer_notifications.all? { |n| n.customer == @customer }
  end

  # Methods - mark_as_read
  test "mark_as_read sets read_at" do
    notification = Notification.create!(
      customer: @customer,
      title: "Test",
      body: "Test body",
      notification_type: "general"
    )

    assert_nil notification.read_at
    notification.mark_as_read
    assert notification.read_at.present?
  end

  test "mark_as_read does not update if already read" do
    notification = Notification.create!(
      customer: @customer,
      title: "Test",
      body: "Test body",
      notification_type: "general",
      read_at: 1.hour.ago
    )

    original_read_at = notification.read_at
    notification.mark_as_read

    # Should not update since it's already read
    assert_equal original_read_at, notification.read_at
  end

  # Methods - read?
  test "read? returns true when read_at is present" do
    notification = Notification.create!(
      customer: @customer,
      title: "Test",
      body: "Test body",
      notification_type: "general",
      read_at: Time.current
    )

    assert notification.read?
  end

  test "read? returns false when read_at is nil" do
    notification = Notification.create!(
      customer: @customer,
      title: "Test",
      body: "Test body",
      notification_type: "general"
    )

    assert_not notification.read?
  end

  # Methods - unread?
  test "unread? returns true when read_at is nil" do
    notification = Notification.create!(
      customer: @customer,
      title: "Test",
      body: "Test body",
      notification_type: "general"
    )

    assert notification.unread?
  end

  test "unread? returns false when read_at is present" do
    notification = Notification.create!(
      customer: @customer,
      title: "Test",
      body: "Test body",
      notification_type: "general",
      read_at: Time.current
    )

    assert_not notification.unread?
  end

  # Class Methods - send_payment_reminder
  test "send_payment_reminder creates payment_reminder notification" do
    installment = installments(:installment_one)

    notification = Notification.send_payment_reminder(@customer, installment)

    assert notification.persisted?
    assert_equal "payment_reminder", notification.notification_type
    assert_equal @customer, notification.customer
    assert_includes notification.title, "Recordatorio"
    assert_includes notification.body, "#{installment.amount}"
  end

  test "send_payment_reminder includes installment due_date" do
    installment = installments(:installment_one)

    notification = Notification.send_payment_reminder(@customer, installment)

    assert_includes notification.body, installment.due_date.strftime('%d/%m/%Y')
  end

  test "send_payment_reminder stores metadata" do
    installment = installments(:installment_one)

    notification = Notification.send_payment_reminder(@customer, installment)

    assert notification.metadata["installment_id"] == installment.id
    assert notification.metadata["loan_id"] == installment.loan_id
  end

  # Class Methods - send_device_lock_warning
  test "send_device_lock_warning creates device_lock notification" do
    device = devices(:device_one)

    notification = Notification.send_device_lock_warning(@customer, device, 3)

    assert notification.persisted?
    assert_equal "device_lock", notification.notification_type
    assert_equal @customer, notification.customer
    assert_includes notification.title, "bloqueo"
  end

  test "send_device_lock_warning includes days_to_unlock" do
    device = devices(:device_one)
    days = 5

    notification = Notification.send_device_lock_warning(@customer, device, days)

    assert_includes notification.body, "#{days}"
  end

  test "send_device_lock_warning stores metadata" do
    device = devices(:device_one)

    notification = Notification.send_device_lock_warning(@customer, device, 3)

    assert notification.metadata["device_id"] == device.id
    assert notification.metadata["days_to_unlock"] == 3
  end

  test "send_device_lock_warning defaults days_to_unlock to 3" do
    device = devices(:device_one)

    notification = Notification.send_device_lock_warning(@customer, device)

    assert notification.metadata["days_to_unlock"] == 3
  end

  # Class Methods - send_payment_confirmation
  test "send_payment_confirmation creates payment_confirmation notification" do
    payment = payments(:payment_one)

    notification = Notification.send_payment_confirmation(@customer, payment)

    assert notification.persisted?
    assert_equal "payment_confirmation", notification.notification_type
    assert_equal @customer, notification.customer
    assert_includes notification.title, "confirmado"
  end

  test "send_payment_confirmation includes payment amount" do
    payment = payments(:payment_one)

    notification = Notification.send_payment_confirmation(@customer, payment)

    assert_includes notification.body, "#{payment.amount}"
  end

  test "send_payment_confirmation stores metadata" do
    payment = payments(:payment_one)

    notification = Notification.send_payment_confirmation(@customer, payment)

    assert notification.metadata["payment_id"] == payment.id
  end

  # Callbacks
  test "sets sent_at on creation" do
    notification = Notification.create!(
      customer: @customer,
      title: "Test",
      body: "Body",
      notification_type: "general"
    )

    assert notification.sent_at.present?
  end

  test "sent_at is not overwritten if already set" do
    past_time = 1.day.ago

    notification = Notification.new(
      customer: @customer,
      title: "Test",
      body: "Body",
      notification_type: "general",
      sent_at: past_time
    )
    notification.save

    assert_equal past_time.to_i, notification.sent_at.to_i
  end

  # Persistence
  test "persists notification with all attributes" do
    notification = Notification.create!(
      customer: @customer,
      title: "Important Update",
      body: "This is an important message",
      notification_type: "payment_reminder",
      metadata: { key: "value" }
    )

    assert notification.persisted?
    assert_not_nil notification.id

    reloaded = Notification.find(notification.id)
    assert_equal "Important Update", reloaded.title
    assert_equal "This is an important message", reloaded.body
    assert_equal "payment_reminder", reloaded.notification_type
  end

  test "updates notification attributes" do
    notification = Notification.create!(
      customer: @customer,
      title: "Original Title",
      body: "Original body",
      notification_type: "general"
    )

    notification.title = "Updated Title"
    notification.save

    assert_equal "Updated Title", notification.reload.title
  end

  test "marks as read and saves" do
    notification = Notification.create!(
      customer: @customer,
      title: "Test",
      body: "Body",
      notification_type: "general"
    )

    notification.mark_as_read
    notification.save

    assert notification.reload.read?
  end

  test "destroys notification" do
    notification = Notification.create!(
      customer: @customer,
      title: "Test",
      body: "Body",
      notification_type: "general"
    )
    notification_id = notification.id

    notification.destroy
    assert_nil Notification.find_by(id: notification_id)
  end

  # Edge Cases
  test "handles very long title" do
    notification = Notification.create!(
      customer: @customer,
      title: "A" * 500,
      body: "Body",
      notification_type: "general"
    )

    assert notification.persisted?
    assert_equal 500, notification.title.length
  end

  test "handles very long body" do
    notification = Notification.create!(
      customer: @customer,
      title: "Title",
      body: "B" * 5000,
      notification_type: "general"
    )

    assert notification.persisted?
    assert_equal 5000, notification.body.length
  end

  test "handles metadata with nested structure" do
    notification = Notification.create!(
      customer: @customer,
      title: "Title",
      body: "Body",
      notification_type: "general",
      metadata: {
        user: {
          id: 123,
          name: "Test",
          nested: { key: "value" }
        },
        amounts: [100, 200, 300]
      }
    )

    assert notification.persisted?
    assert_equal 123, notification.metadata["user"]["id"]
    assert_includes notification.metadata["amounts"], 200
  end

  test "handles empty metadata" do
    notification = Notification.create!(
      customer: @customer,
      title: "Title",
      body: "Body",
      notification_type: "general",
      metadata: {}
    )

    assert notification.persisted?
    assert_equal({}, notification.metadata)
  end

  test "multiple unread notifications for same customer" do
    notification1 = Notification.create!(
      customer: @customer,
      title: "Title 1",
      body: "Body 1",
      notification_type: "general"
    )

    notification2 = Notification.create!(
      customer: @customer,
      title: "Title 2",
      body: "Body 2",
      notification_type: "payment_reminder"
    )

    unread = Notification.by_customer(@customer).unread
    assert unread.count >= 2
  end
end
