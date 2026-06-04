# frozen_string_literal: true

require "test_helper"

class CleanupOldNotificationsJobTest < ActiveSupport::TestCase
  setup { @customer = customers(:customer_one) }

  test "purges old failed notifications but keeps recent and delivered ones" do
    old_failed     = aged_notification(status: "failed", age_days: 10)
    old_permanent  = aged_notification(status: "failed_permanent", age_days: 10)
    recent_failed  = aged_notification(status: "failed", age_days: 1)
    old_delivered  = aged_notification(status: "delivered", age_days: 10)

    CleanupOldNotificationsJob.perform_now

    assert_not Notification.exists?(old_failed.id),    "old failed should be purged"
    assert_not Notification.exists?(old_permanent.id), "old failed_permanent should be purged"
    assert Notification.exists?(recent_failed.id),     "recent failed should be kept"
    assert Notification.exists?(old_delivered.id),     "delivered should not be purged by the failed sweep"
  end

  private

  def aged_notification(status:, age_days:)
    n = Notification.create!(
      customer: @customer, title: "T", message: "M",
      notification_type: "general", status: status
    )
    n.update_columns(created_at: age_days.days.ago, updated_at: age_days.days.ago)
    n
  end
end
