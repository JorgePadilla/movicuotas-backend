module Api
  module V1
    class InstallmentsController < BaseController
      def index
        customer = current_customer
        loan = customer.loans.active.first

        return render_error("No active loan found", :not_found) unless loan

        installments = loan.installments.order(:due_date)
        serialized_installments = installments.map { |i| InstallmentSerializer.new(i).as_json }

        render_success({
          installments: serialized_installments,
          summary: {
            total_installments: installments.count,
            pending: installments.pending.count,
            paid: installments.paid.count,
            overdue: installments.overdue.count
          }
        })
      end
    end
  end
end
