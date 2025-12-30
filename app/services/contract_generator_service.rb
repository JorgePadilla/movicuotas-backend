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
      template: "vendor/contracts/_contract_content",
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

  # Generate PDF using Prawn
  def generate_pdf
    require 'prawn'
    require 'prawn/table'
    Prawn::Fonts::AFM.hide_m17n_warning = true

    Prawn::Document.new(page_size: 'LETTER', page_layout: :portrait, margin: 72) do |pdf|
      # Header with logo and title
      pdf.font_size 24
      pdf.text 'CONTRATO DE CRÉDITO', align: :center, style: :bold, color: '125282'
      pdf.move_down 20

      # Contract number and date
      pdf.font_size 12
      pdf.text "Número de Contrato: #{@loan.contract_number}", align: :right
      pdf.text "Fecha: #{Date.today.strftime('%d/%m/%Y')}", align: :right
      pdf.move_down 30

      # Parties section
      pdf.font_size 16
      pdf.text 'PARTES', style: :bold
      pdf.move_down 10
      pdf.font_size 12
      pdf.text "1. <b>CLIENTE:</b> #{@customer.full_name}", inline_format: true
      pdf.text "   Identificación: #{@customer.identification_number}"
      pdf.text "   Teléfono: #{@customer.phone}"
      pdf.text "   Dirección: #{@customer.address}, #{@customer.city}, #{@customer.department}"
      pdf.move_down 10
      pdf.text "2. <b>MOVICUOTAS:</b> Tu Crédito, Tu Móvil", inline_format: true
      pdf.text "   Representante: Sistema de Crédito Automatizado"
      pdf.move_down 30

      # Device information
      pdf.font_size 16
      pdf.text 'EQUIPO ADQUIRIDO', style: :bold
      pdf.move_down 10
      pdf.font_size 12
      pdf.text "Marca: #{@device.brand}"
      pdf.text "Modelo: #{@device.model}"
      pdf.text "Color: #{@device.color}" if @device.color.present?
      pdf.text "IMEI: #{@device.imei}"
      pdf.text "Precio Total: #{format_currency(@loan.total_amount)}"
      pdf.move_down 30

      # Financial terms
      pdf.font_size 16
      pdf.text 'TÉRMINOS FINANCIEROS', style: :bold
      pdf.move_down 10
      pdf.font_size 12
      pdf.text "Pago Inicial: #{@loan.down_payment_percentage}% (#{format_currency(@loan.down_payment_amount)})"
      pdf.text "Monto Financiado: #{format_currency(@loan.financed_amount)}"
      pdf.text "Tasa de Interés Quincenal: #{@loan.interest_rate}%"
      pdf.text "Número de Cuotas: #{@loan.number_of_installments} (quincenales)"
      pdf.text "Fecha de Inicio: #{@loan.start_date.strftime('%d/%m/%Y')}"
      pdf.text "Fecha de Finalización: #{@loan.end_date.strftime('%d/%m/%Y')}"
      pdf.move_down 30

      # Installment schedule
      pdf.font_size 16
      pdf.text 'CALENDARIO DE PAGOS', style: :bold
      pdf.move_down 10

      if @loan.installments.any?
        data = [['#', 'Fecha Vencimiento', 'Monto', 'Estado']]
        @loan.installments.order(:installment_number).each do |inst|
          data << [
            inst.installment_number,
            inst.due_date.strftime('%d/%m/%Y'),
            format_currency(inst.amount),
            inst.status.upcase
          ]
        end

        pdf.table(data, header: true, width: pdf.bounds.width) do |table|
          table.row(0).font_style = :bold
          table.row(0).background_color = 'f3f4f6'
          table.columns(0..3).align = :center
          table.columns(1).align = :left
        end
      end

      pdf.move_down 30

      # Terms and conditions
      pdf.font_size 16
      pdf.text 'TÉRMINOS Y CONDICIONES', style: :bold
      pdf.move_down 10
      pdf.font_size 10
      terms = [
        "1. El cliente se compromete a realizar los pagos quincenales en las fechas establecidas.",
        "2. En caso de mora, se aplicará un recargo del 10% sobre la cuota vencida.",
        "3. MOVICUOTAS se reserva el derecho de bloquear el dispositivo mediante MDM en caso de mora mayor a 30 días.",
        "4. El cliente autoriza a MOVICUOTAS a verificar su información crediticia y laboral.",
        "5. Este contrato es válido por la duración del financiamiento y se rige por las leyes de Honduras.",
        "6. Cualquier disputa será resuelta mediante arbitraje en la ciudad de Tegucigalpa.",
        "7. El cliente acepta las políticas de privacidad y tratamiento de datos de MOVICUOTAS.",
        "8. Este documento tiene validez legal como contrato firmado digitalmente."
      ]

      terms.each do |term|
        pdf.text term, indent_paragraphs: 20
      end

      pdf.move_down 40

      # Signature lines
      pdf.font_size 12
      pdf.text '___________________________', align: :left
      pdf.text 'Firma del Cliente', align: :left
      pdf.move_down 20
      pdf.text '___________________________', align: :right
      pdf.text 'MOVICUOTAS - Tu Crédito, Tu Móvil', align: :right

      # Footer
      pdf.repeat(:all) do
        pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom + 40], width: pdf.bounds.width) do
          pdf.font_size 8
          pdf.text "Contrato generado automáticamente el #{Time.current.strftime('%d/%m/%Y %H:%M')}. Documento válido sin firma física.",
                   align: :center, color: '6b7280'
        end
      end
    end.render
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
    when "paid"
      "color: #10b981; font-weight: bold;"
    when "overdue"
      "color: #ef4444; font-weight: bold;"
    when "pending"
      "color: #f59e0b; font-weight: bold;"
    else
      "color: #6b7280;"
    end
  end
end
