## Background Jobs for Collection

### NotifyCollectionAgentJob

```ruby
class NotifyCollectionAgentJob < ApplicationJob
  queue_as :notifications

  def perform
    # Notify cobradores daily about new overdue accounts
    overdue_today = Installment.where(
      due_date: Date.yesterday,
      status: 'pending'
    ).update_all(status: 'overdue')

    if overdue_today > 0
      User.where(role: 'cobrador').find_each do |cobrador|
        CollectionMailer.daily_overdue_report(cobrador).deliver_later
      end
    end
  end
end
```

### AutoBlockDeviceJob

```ruby
class AutoBlockDeviceJob < ApplicationJob
  queue_as :mdm_actions

  def perform
    # Auto-block devices with 30+ days overdue
    critical_overdue = Device.joins(loan: :installments)
                             .where(installments: { status: 'overdue' })
                             .where('installments.due_date < ?', 30.days.ago)
                             .where(lock_status: 'unlocked')
                             .distinct

    critical_overdue.each do |device|
      MdmBlockService.new(device, User.system_user).block!
    end
  end
end
```

