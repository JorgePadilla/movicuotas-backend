module Api
  module V1
    class DashboardController < BaseController
      def show
        customer = current_customer
        loan = customer.loans.active.first

        return render_error("No active loan found", :not_found) unless loan

        next_payment = loan.installments.pending.order(:due_date).first
        overdue_count = loan.installments.overdue.count
        total_overdue_amount = loan.installments.overdue.sum(:amount)

        render_success({
          customer: CustomerSerializer.new(customer).as_json,
          loan: LoanSerializer.new(loan).as_json,
          next_payment: next_payment ? InstallmentSerializer.new(next_payment).as_json : nil,
          overdue_count: overdue_count,
          total_overdue_amount: total_overdue_amount,
          device_status: get_device_status(loan),
          unread_notifications_count: customer.notifications.unread.count
        })
      end

      private

      def get_device_status(loan)
        device = loan.device
        return nil unless device

        phone_model = device.phone_model
        phone_model_name = phone_model ? "#{phone_model.brand} #{phone_model.model}" : nil

        {
          imei: device.imei,
          phone_model: phone_model_name,
          lock_status: device.lock_status,
          is_blocked: device.locked?
        }
      end
    end
  end
end
