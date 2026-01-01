module Api
  module V1
    class PaymentsController < BaseController
      def create
        customer = current_customer
        installment = Installment.find_by(id: payment_params[:installment_id], loan: customer.loans)

        return render_error("Installment not found", :not_found) unless installment

        payment = Payment.new(
          installment: installment,
          amount: payment_params[:amount],
          payment_date: payment_params[:payment_date],
          status: "pending"
        )

        if payment_params[:receipt_image].present?
          payment.receipt_image.attach(payment_params[:receipt_image])
        end

        if payment.save
          # Notify admin about new payment submission
          notify_payment_received(payment)

          render_success({
            id: payment.id,
            status: payment.status,
            message: "Payment submitted successfully. Please wait for verification."
          }, :created)
        else
          render_error(payment.errors.full_messages.join(", "), :unprocessable_entity)
        end
      end

      private

      def payment_params
        params.require(:payment).permit(:installment_id, :amount, :payment_date, :receipt_image)
      end

      def notify_payment_received(payment)
        # TODO: Implement notification system
        Rails.logger.info "Payment received: #{payment.id} for installment #{payment.installment.id}"
      end
    end
  end
end
