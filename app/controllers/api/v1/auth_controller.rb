module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_api_user, only: [ :login, :forgot_contract ]

      def login
        customer = Customer.find_by(identification_number: login_params[:identification_number])

        return render_error("Invalid credentials", :unauthorized) unless customer

        loan = customer.loans.where(contract_number: login_params[:contract_number]).first

        return render_error("Invalid credentials", :unauthorized) unless loan

        token = generate_token(customer)

        render_success({
          token: token,
          customer: CustomerSerializer.new(customer).as_json,
          loan: LoanSerializer.new(loan).as_json
        })
      end

      def forgot_contract
        customer = Customer.find_by(phone: forgot_contract_params[:phone])

        return render_error("Customer not found", :not_found) unless customer

        loan = customer.loans.active.first

        return render_error("No active loan found", :not_found) unless loan

        send_contract_sms(customer, loan)

        render_success({ message: "Contract number sent to #{customer.phone}" })
      end

      private

      def login_params
        params.require(:auth).permit(:identification_number, :contract_number)
      end

      def forgot_contract_params
        params.permit(:phone)
      end

      def generate_token(customer)
        payload = {
          customer_id: customer.id,
          exp: 30.days.from_now.to_i,
          iat: Time.now.to_i
        }

        JWT.encode(payload, Rails.application.secret_key_base, "HS256")
      end

      def send_contract_sms(customer, loan)
        # TODO: Implement SMS service integration
        # For now, we'll just log that this would be sent
        Rails.logger.info "Would send SMS to #{customer.phone}: Contract #{loan.contract_number}"
      end
    end
  end
end
