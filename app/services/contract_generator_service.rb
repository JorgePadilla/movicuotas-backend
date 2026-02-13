# app/services/contract_generator_service.rb
class ContractGeneratorService
  # Initialize with a Loan or Contract object
  def initialize(contract)
    @contract = contract
    @loan = contract.loan
    @customer = @loan.customer
    @device = @loan.device

    # Fall back to credit application data if device is missing
    if @device.nil?
      @credit_application = find_credit_application_for_customer
      @phone_model = @credit_application&.selected_phone_model
    else
      @phone_model = @device.phone_model
    end
  end

  # Find the most recent approved credit application for this customer
  def find_credit_application_for_customer
    @customer.credit_applications
             .where(status: "approved")
             .where.not(selected_phone_model_id: nil)
             .order(created_at: :desc)
             .first
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
        credit_application: @credit_application,
        service: self,
        installment_details: installment_details
      }
    )
  end

  # Generate PDF using Prawn
  def generate_pdf
    require "prawn"
    require "prawn/table"
    Prawn::Fonts::AFM.hide_m17n_warning = true

    Prawn::Document.new(page_size: "LETTER", page_layout: :portrait, margin: 72) do |pdf|
      # Header with logo and title
      pdf.font_size 24
      pdf.text "CONTRATO DE CRÉDITO", align: :center, style: :bold, color: "125282"
      pdf.move_down 20

      # Contract number and date
      pdf.font_size 12
      pdf.text "Número de Contrato: #{@loan.contract_number}", align: :right
      pdf.text "Fecha: #{Date.today.strftime('%d/%m/%Y')}", align: :right
      pdf.move_down 20

      # Introductory Paragraph
      pdf.font_size 12
      pdf.text "Nosotros, MoviCuotas S. de R.L., que en adelante se denominará \"LA EMPRESA\", y el cliente, identificado en este documento en la Sección 1, que en adelante se denominará \"EL CLIENTE\", hemos convenido en celebrar como al efecto por este acto celebramos el presente CONTRATO DE CRÉDITO.", align: :justify
      pdf.move_down 10
      pdf.text "Este contrato regula los términos bajo los cuales LA EMPRESA otorga a EL CLIENTE un crédito quincenal para la compra del dispositivo móvil descrito en la Sección 1.", align: :justify
      pdf.move_down 20

      # Section 1: Datos del Cliente y del Crédito
      pdf.font_size 16
      pdf.text "1. Datos del Cliente y del Crédito", style: :bold
      pdf.move_down 15

      pdf.font_size 12
      pdf.text "<b>Datos del Cliente</b>", inline_format: true
      pdf.move_down 5
      pdf.text "Nombre del Cliente: #{@customer.full_name}"
      pdf.text "Identidad: #{@customer.identification_number}"
      pdf.text "Teléfono: #{@customer.phone}"
      pdf.text "Correo electrónico: #{@customer.email.present? ? @customer.email : '_______________________________________'}"
      pdf.text "Dirección: #{@customer.address}, #{@customer.city}, #{@customer.department}"
      pdf.move_down 10

      pdf.text "<b>Datos del Dispositivo</b>", inline_format: true
      pdf.move_down 5
      # Use device data if available, otherwise fall back to credit_application data
      device_brand_model = if @device.present?
                             "#{@device.brand} / #{@device.model}"
      elsif @credit_application&.selected_phone_model.present?
                             "#{@credit_application.selected_phone_model.brand} / #{@credit_application.selected_phone_model.model}"
      else
                             "_________________________________________"
      end
      device_color = if @device.present? && @device.color.present?
                       @device.color
      elsif @credit_application&.selected_color.present?
                       @credit_application.selected_color
      else
                       "_________________________________________"
      end
      device_imei = if @device.present?
                      @device.imei
      elsif @credit_application&.selected_imei.present?
                      @credit_application.selected_imei
      else
                      "_________________________________________________"
      end
      pdf.text "Marca / Modelo: #{device_brand_model}"
      pdf.text "Color: #{device_color}"
      pdf.text "IMEI: #{device_imei}"
      pdf.move_down 10

      pdf.text "<b>Datos del Crédito (Quincenal)</b>", inline_format: true
      pdf.move_down 5
      pdf.text "Precio al contado: #{format_currency(@loan.total_amount)}"
      pdf.text "Prima: #{format_currency(@loan.down_payment_amount)}"
      pdf.text "Monto financiado: #{format_currency(@loan.financed_amount)}"
      pdf.text "Número total de cuotas quincenales: #{@loan.number_of_installments}"
      pdf.text "Cuota quincenal: #{format_currency((@loan.installments.first&.amount || @loan.financed_amount / @loan.number_of_installments).ceil)}"
      pdf.text "Fecha de inicio del contrato: #{@loan.start_date.strftime('%d/%m/%Y')}"
      pdf.text "Fecha de pago quincenal: Cada 15 Días comenzando a partir de la fecha de inicio del contrato."
      pdf.move_down 20

      # Installment schedule
      pdf.font_size 16
      pdf.text "CRONOGRAMA DE PAGOS", style: :bold
      pdf.move_down 10

      if @loan.installments.any?
        data = [ [ "#", "Fecha Vencimiento", "Monto", "Estado" ] ]
        @loan.installments.order(:installment_number).each do |inst|
          data << [
            inst.installment_number,
            inst.due_date.strftime("%d/%m/%Y"),
            format_currency(inst.amount.ceil),
            I18n.t("installment.status.#{inst.status}", default: inst.status).upcase
          ]
        end

        pdf.table(data, header: true, width: pdf.bounds.width) do |table|
          table.row(0).font_style = :bold
          table.row(0).background_color = "f3f4f6"
          table.columns(0..3).align = :center
          table.columns(1).align = :left
        end
      end

      pdf.move_down 20

      # Sections 2-11 from new contract
      pdf.font_size 16
      pdf.text "2. Objeto del Contrato", style: :bold
      pdf.move_down 10
      pdf.font_size 12
      pdf.text "LA EMPRESA otorga a EL CLIENTE un crédito con pagos quincenales para adquirir un dispositivo móvil.", align: :justify
      pdf.text "EL CLIENTE acepta pagar las cuotas cada quincena según los montos y fechas acordadas.", align: :justify
      pdf.move_down 15

      pdf.font_size 16
      pdf.text "3. Compromisos y Obligaciones del Cliente", style: :bold
      pdf.move_down 10
      pdf.font_size 12
      pdf.text "EL CLIENTE se compromete a:", align: :justify
      pdf.text "1. Realizar los pagos cada quincena, en la fecha acordada."
      pdf.text "2. Cumplir con la prima inicial."
      pdf.text "3. Mantener actualizado su teléfono y dirección."
      pdf.text "4. No manipular, desactivar, eliminar o interferir con el software de control instalado en el dispositivo."
      pdf.text "5. No ceder, vender o transferir el dispositivo hasta pagar totalmente el crédito."
      pdf.move_down 15

      pdf.font_size 16
      pdf.text "4. Bloqueo Remoto del Dispositivo", style: :bold
      pdf.move_down 10
      pdf.font_size 12
      pdf.text "EL CLIENTE acepta que:", align: :justify
      pdf.text "1. El dispositivo incluye un software de gestión y control remoto (MoviCuotas)."
      pdf.text "2. Si EL CLIENTE no realiza el pago quincenal en la fecha indicada, LA EMPRESA podrá:"
      pdf.text "   a) Notificar automáticamente el retraso."
      pdf.text "   b) Bloquear el dispositivo de forma remota al confirmarse el vencimiento de la cuota."
      pdf.text "3. El dispositivo bloqueado podrá:"
      pdf.text "   a) Mostrar notificaciones de mora"
      pdf.text "   b) Mostrar el saldo pendiente"
      pdf.text "   c) Permitir enviar comprobantes de pago"
      pdf.text "4. El bloqueo se mantendrá hasta que EL CLIENTE se ponga al día."
      pdf.text "5. EL CLIENTE declara que comprende y autoriza esta medida como parte del acceso al crédito de MoviCuotas."
      pdf.move_down 15

      pdf.font_size 16
      pdf.text "5. Política de Privacidad y Uso de Datos", style: :bold
      pdf.move_down 10
      pdf.font_size 12
      pdf.text "LA EMPRESA recopila la siguiente información:", align: :justify
      pdf.text "• Datos personales proporcionados por EL CLIENTE"
      pdf.text "• Fotografía del documento de identidad"
      pdf.text "• Historial del crédito y los pagos quincenales"
      pdf.text "• Identificación del dispositivo (IMEI, marca, modelo)"
      pdf.text "• Información técnica necesaria para el bloqueo/desbloqueo"
      pdf.move_down 5
      pdf.text "<b>Finalidad del uso de datos</b>", inline_format: true
      pdf.text "Los datos serán utilizados para:", align: :justify
      pdf.text "1. Evaluación del crédito."
      pdf.text "2. Gestión del cronograma quincenal de pagos."
      pdf.text "3. Verificación de identidad."
      pdf.text "4. Envío de notificaciones y recordatorios."
      pdf.text "5. Activación y desactivación del control remoto del dispositivo."
      pdf.move_down 5
      pdf.text "LA EMPRESA no vende ni comparte los datos con terceros, salvo requerimientos legales o servicios estrictamente necesarios para la operación del sistema MoviCuotas.", align: :justify
      pdf.move_down 15

      pdf.font_size 16
      pdf.text "6. Pagos, Atrasos y Penalidades (Quincenales)", style: :bold
      pdf.move_down 10
      pdf.font_size 12
      pdf.text "1. El pago debe realizarse quincenalmente en las fechas acordadas."
      pdf.text "2. En caso de retraso, LA EMPRESA podrá aplicar:"
      pdf.text "   a) Bloqueo del dispositivo hasta ponerse al día"
      pdf.text "3. Si un atraso supera dos quincenas consecutivas, LA EMPRESA podrá:"
      pdf.text "   a) Declarar la deuda vencida"
      pdf.text "   b) Exigir devolución del dispositivo"
      pdf.text "   c) Proceder a cobro extrajudicial o judicial"
      pdf.move_down 5
      pdf.font_size 14
      pdf.text "6A. Garantía del Dispositivo y Relación con el Crédito", style: :bold
      pdf.font_size 12
      pdf.text "1. EL CLIENTE reconoce y acepta que el dispositivo adquirido cuenta con una garantía limitada, cuyos términos, condiciones, exclusiones y alcances se encuentran detallados en un documento independiente denominado \"Certificado de Garantía\", el cual ha sido entregado, leído y aceptado por EL CLIENTE."
      pdf.text "2. EL CLIENTE declara expresamente que acepta en su totalidad todas las condiciones establecidas en el Certificado de Garantía, el cual forma parte integral del presente contrato, aunque se encuentre en documento separado."
      pdf.text "3. En caso de que el dispositivo presente un desperfecto y deba ingresar a diagnóstico, revisión o reparación en el taller técnico de LA EMPRESA o en un taller autorizado por el fabricante, dicha situación no suspende, interrumpe ni anula la obligación de EL CLIENTE de pagar puntualmente las cuotas quincenales del crédito."
      pdf.text "4. EL CLIENTE acepta que el tiempo que el dispositivo permanezca en diagnóstico o reparación no genera prórroga, descuento, compensación ni exoneración de las cuotas del crédito, intereses, cargos o cualquier otra obligación derivada del presente contrato."
      pdf.text "5. La garantía no cubre daños ocasionados por golpes, humedad, manipulación de software no autorizado, intentos de eliminación o alteración del sistema de control remoto de MoviCuotas, ni cualquier otra causal detallada en el Certificado de Garantía."
      pdf.text "6. En caso de que el dispositivo sea declarado fuera de garantía, EL CLIENTE continuará siendo responsable del pago total del crédito otorgado, independientemente del estado funcional del dispositivo."
      pdf.move_down 15

      pdf.font_size 16
      pdf.text "7. Cancelación del Crédito", style: :bold
      pdf.move_down 10
      pdf.font_size 12
      pdf.text "El crédito se considera finalizado cuando:", align: :justify
      pdf.text "1. EL CLIENTE paga todas las cuotas quincenales."
      pdf.text "2. LA EMPRESA registra el pago final."
      pdf.text "3. El dispositivo es desbloqueado de forma permanente."
      pdf.move_down 15

      pdf.font_size 16
      pdf.text "8. Propiedad del Dispositivo", style: :bold
      pdf.move_down 10
      pdf.font_size 12
      pdf.text "El dispositivo sigue siendo propiedad de LA EMPRESA mientras exista saldo pendiente.", align: :justify
      pdf.text "Una vez pagado el crédito, se transfiere a EL CLIENTE de forma definitiva.", align: :justify
      pdf.move_down 15

      pdf.font_size 16
      pdf.text "9. Comunicaciones, Notificaciones y Alertas", style: :bold
      pdf.move_down 10
      pdf.font_size 12
      pdf.text "EL CLIENTE acepta recibir:", align: :justify
      pdf.text "• Recordatorios de pago quincenal"
      pdf.text "• Alertas de mora"
      pdf.text "• Notificaciones de bloqueo/desbloqueo"
      pdf.text "• Comunicaciones administrativas"
      pdf.move_down 5
      pdf.text "Las comunicaciones pueden enviarse por SMS, WhatsApp, llamadas telefónicas o mensajes desde la app MoviCuotas.", align: :justify
      pdf.move_down 15

      pdf.font_size 16
      pdf.text "10. Jurisdicción", style: :bold
      pdf.move_down 10
      pdf.font_size 12
      pdf.text "Este contrato se rige por las leyes de la República de Honduras.", align: :justify
      pdf.text "Cualquier disputa será resuelta en los juzgados competentes del domicilio de LA EMPRESA.", align: :justify
      pdf.move_down 15

      pdf.font_size 16
      pdf.text "11. Aceptación y Firma", style: :bold
      pdf.move_down 10
      pdf.font_size 12
      pdf.text "Firmando este documento, EL CLIENTE declara haber leído, entendido y aceptado:", align: :justify
      pdf.text "• Las condiciones del crédito quincenal"
      pdf.text "• La Política de Privacidad"
      pdf.text "• La autorización para bloqueo remoto del dispositivo"
      pdf.text "• La totalidad de los términos y obligaciones aquí descritos"
      pdf.move_down 20

      # Signature lines
      pdf.font_size 12
      pdf.text "___________________________", align: :left
      pdf.text "EL CLIENTE", align: :left
      pdf.text "#{@customer.full_name}", align: :left
      pdf.text "No. Identidad: #{@customer.identification_number}", align: :left
      pdf.move_down 20
      pdf.text "___________________________", align: :right
      pdf.text "LA EMPRESA", align: :right
      pdf.text "MOVICUOTAS", align: :right
      pdf.text "Representante: #{@loan.user&.full_name || 'Supervisor Autorizado'}", align: :right
      pdf.text "Sucursal: #{@loan.branch_number}", align: :right

      # Footer in bottom margin
      pdf.repeat(:all) do
        pdf.canvas do
          pdf.font_size 8
          pdf.fill_color "6b7280"
          pdf.draw_text "Contrato generado automáticamente el #{Time.current.strftime('%d/%m/%Y %H:%M')}. Documento válido sin firma física.",
                        at: [72, 20]
          pdf.fill_color "000000"
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
        amount: format_currency(installment.amount.ceil),
        status: installment.status
      }
    end
  end

  # Format currency in Honduran Lempiras
  def format_currency(amount)
    amount_float = amount.to_f
    if amount_float % 1 == 0
      "L. #{amount_float.to_i}"
    else
      "L. #{amount_float.round(2)}"
    end
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
    when "cancelled"
      "color: #9ca3af; font-weight: bold;"
    else
      "color: #6b7280;"
    end
  end

  private

  # Add activation code section to PDF
  def add_activation_code_section(pdf)
    activation_code = @device&.activation_code || "------"
    box_height = 80

    # Use bounding_box to contain both the background and text
    top = pdf.cursor
    pdf.bounding_box([ 0, top ], width: pdf.bounds.width, height: box_height) do
      # Draw blue background filling the entire box
      pdf.fill_color "E8F4FD"
      pdf.fill_rectangle [ 0, box_height ], pdf.bounds.width, box_height
      pdf.fill_color "000000"

      pdf.move_down 10
      pdf.font_size 12
      pdf.text "CODIGO DE ACTIVACION", style: :bold, align: :center
      pdf.move_down 8
      pdf.font_size 28
      pdf.text activation_code, style: :bold, align: :center, color: "125282"
      pdf.font_size 9
      pdf.move_down 8
      pdf.text "Ingrese este codigo en la app MOVICUOTAS para activar su dispositivo", align: :center
    end
  end
end
