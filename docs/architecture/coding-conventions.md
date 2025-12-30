## Critical Patterns to Follow

### 1. Service Objects for Business Logic
```ruby
# Good: Extract complex logic to services
class LoanCalculatorService
  def initialize(loan)
    @loan = loan
  end

  def generate_installments
    # Complex calculation here
  end
end

# Usage in controller
service = LoanCalculatorService.new(loan)
installments = service.generate_installments
```

### 2. Background Jobs for Async Work
```ruby
# Use Solid Queue for notifications
class SendPaymentReminderJob < ApplicationJob
  queue_as :notifications

  def perform(customer_id, installment_id)
    # Send FCM notification
  end
end
```

### 3. ViewComponents for UI
```ruby
# app/components/admin/customers/customer_card_component.rb
class Admin::Customers::CustomerCardComponent < ViewComponent::Base
  def initialize(customer:)
    @customer = customer
  end

  def status_color
    case @customer.status
    when 'active' then '#10b981'      # Green - Success
    when 'suspended' then '#f59e0b'   # Orange - Warning
    when 'blocked' then '#ef4444'     # Red - Error
    end
  end

  def status_badge_class
    case @customer.status
    when 'active' then 'bg-green-100 text-green-800'
    when 'suspended' then 'bg-orange-100 text-orange-800'
    when 'blocked' then 'bg-red-100 text-red-800'
    end
  end
end
```

**Important**: Always use the defined color palette:
- Primary brand: `#125282`
- Success/approved: `#10b981`
- Error/rejected: `#ef4444`
- Warning/pending: `#f59e0b`
- Info: `#3b82f6`
- Products: `#6366f1`

### 4. Pundit for Authorization

**Policy Examples for Cobrador Role:**

```ruby
# app/policies/device_policy.rb
class DevicePolicy < ApplicationPolicy
  def lock?
    user.admin? || user.cobrador? # Cobrador CAN block devices
  end

  def unlock?
    user.admin? # Only admin can unlock
  end

  def destroy?
    user.admin? # Cobrador CANNOT delete
  end
end

# app/policies/payment_policy.rb
class PaymentPolicy < ApplicationPolicy
  def index?
    true # Everyone can view
  end

  def show?
    true # Everyone can view details
  end

  def create?
    user.admin? || user.vendedor? # Cobrador CANNOT create
  end

  def update?
    user.admin? # Cobrador CANNOT update
  end

  def destroy?
    user.admin? # Cobrador CANNOT delete
  end
end

# app/policies/loan_policy.rb
class LoanPolicy < ApplicationPolicy
  def index?
    true # Everyone can view
  end

  def show?
    true # Everyone can view details
  end

  def create?
    user.admin? || user.vendedor? # Cobrador CANNOT create
  end

  def update?
    user.admin? || user.vendedor? # Cobrador CANNOT update
  end

  def destroy?
    user.admin? # Cobrador CANNOT delete
  end
end

# app/policies/user_policy.rb
class UserPolicy < ApplicationPolicy
  def index?
    user.admin? # Only admin can view users
  end

  def create?
    user.admin? # Cobrador CANNOT create users
  end

  def update?
    user.admin? # Cobrador CANNOT edit users
  end

  def destroy?
    user.admin? # Cobrador CANNOT delete users
  end
end

# app/policies/customer_policy.rb
class CustomerPolicy < ApplicationPolicy
  def index?
    true # Everyone can view
  end

  def show?
    true # Everyone can view details
  end

  def create?
    user.admin? || user.vendedor? # Cobrador CANNOT create
  end

  def update?
    user.admin? || user.vendedor? # Cobrador CANNOT update
  end

  def destroy?
    user.admin? # Cobrador CANNOT delete
  end

  def block?
    user.admin? # Only admin can block customers
  end
end

# Usage in controllers
def update
  @customer = Customer.find(params[:id])
  authorize @customer
  # ...
end
```

