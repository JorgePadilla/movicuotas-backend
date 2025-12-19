# app/services/contract_generator_service.rb
class ContractGeneratorService
  # Initialize with a Loan or Contract object
  def initialize(contract)
    @contract = contract
    @loan = contract.loan
    @customer = @loan.customer
    @device = @loan.device
    @phone_model = @device&.phone_model
  end

  # Generate HTML contract content
  def generate_html
    ApplicationController.render(
      template: 'vendor/contracts/_contract_content',
      layout: false,
      locals: {
        contract: @contract,
        loan: @loan,
        customer: @customer,
        device: @device,
        phone_model: @phone_model,
        service: self,
        installment_details: installment_details
      }
    )
  end

  # Generate PDF using Prawn (placeholder for future implementation)
  def generate_pdf
    # TODO: Implement PDF generation using Prawn or WickedPDF
    # For now, return HTML that can be rendered as PDF
    generate_html
  end

  # Calculate installment details for display
  def installment_details
    return [] unless @loan.installments.any?

    @loan.installments.order(:installment_number).map do |installment|
      {
        number: installment.installment_number,
        due_date: I18n.l(installment.due_date, format: :long),
        amount: format_currency(installment.amount),
        status: installment.status
      }
    end
  end

  # Format currency in Honduran Lempiras
  def format_currency(amount)
    "L. #{amount.to_f.round(2)}"
  end

  # Format date
  def format_date(date)
    I18n.l(date, format: :long) if date.present?
  end

  # Calculate age from date of birth
  def customer_age
    return nil unless @customer.date_of_birth
    today = Date.today
    age = today.year - @customer.date_of_birth.year
    age -= 1 if today.month < @customer.date_of_birth.month || (today.month == @customer.date_of_birth.month && today.day < @customer.date_of_birth.day)
    age
  end

  # Style for installment status
  def installment_status_style(status)
    case status
    when 'paid'
      'color: #10b981; font-weight: bold;'
    when 'overdue'
      'color: #ef4444; font-weight: bold;'
    when 'pending'
      'color: #f59e0b; font-weight: bold;'
    else
      'color: #6b7280;'
    end
  end
end