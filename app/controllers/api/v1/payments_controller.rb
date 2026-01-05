module Api
  module V1
    class PaymentsController < BaseController
      def create
        customer = current_customer
        installment = Installment.find_by(id: payment_params[:installment_id], loan: customer.loans)

        return render_error("Installment not found", :not_found) unless installment

        payment = Payment.new(
          loan: installment.loan,
          amount: payment_params[:amount],
          payment_date: payment_params[:payment_date],
          payment_method: payment_params[:payment_method] || "transfer",
          verification_status: "pending"
        )

        if payment_params[:receipt_image].present?
          decoded_image = decode_base64_image(payment_params[:receipt_image])
          payment.receipt_image.attach(decoded_image) if decoded_image
        end

        if payment.save
          # Allocate payment to the installment
          payment.allocate_to_installments({ installment.id => payment.amount })

          # Notify admin about new payment submission
          notify_payment_received(payment, installment)

          render_success({
            id: payment.id,
            status: payment.verification_status,
            message: "Payment submitted successfully. Please wait for verification."
          }, :created)
        else
          render_error(payment.errors.full_messages.join(", "), :unprocessable_entity)
        end
      end

      private

      def payment_params
        params.require(:payment).permit(:installment_id, :amount, :payment_date, :payment_method, :receipt_image)
      end

      def decode_base64_image(base64_string)
        return nil if base64_string.blank?

        # Handle data URI format or raw base64
        if base64_string.start_with?("data:")
          content_type, data = base64_string.match(/data:(.*);base64,(.*)/).captures
        else
          content_type = "image/jpeg"
          data = base64_string
        end

        decoded_data = Base64.decode64(data)
        filename = "receipt_#{Time.current.to_i}.#{content_type.split('/').last}"

        {
          io: StringIO.new(decoded_data),
          filename: filename,
          content_type: content_type
        }
      rescue StandardError => e
        Rails.logger.error "Failed to decode base64 image: #{e.message}"
        nil
      end

      def notify_payment_received(payment, installment)
        Rails.logger.info "Payment received: #{payment.id} for installment #{installment.id}"
      end
    end
  end
end
