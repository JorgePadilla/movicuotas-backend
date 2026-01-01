# frozen_string_literal: true

module Admin
  class ReportsController < ApplicationController
    before_action :authorize_admin

    def index
      # Load summary data for report dashboard
      @total_loans = Loan.count
      @total_revenue = Payment.sum(:amount) || 0
      @total_customers = Customer.count

      # Status breakdowns
      @active_loans = Loan.where(status: 'active').count
      @completed_loans = Loan.where(status: 'paid').count
      @overdue_loans = Loan.where(status: 'overdue').count

      # Payment status
      @verified_payments = Payment.verified.sum(:amount) || 0
      @pending_payments = Payment.pending_verification.sum(:amount) || 0
      @rejected_payments = Payment.where(verification_status: 'rejected').sum(:amount) || 0

      # Recent activity
      @new_loans_this_month = Loan.where('loans.created_at >= ?', 1.month.ago).count
      @payments_this_month = Payment.where('payments.payment_date >= ?', 1.month.ago).sum(:amount) || 0

      # Customers with active loans
      @customers_with_active_loans = Customer.joins(:loans).where('loans.status': 'active').distinct.count('customers.id')

      # Branch data
      @loans_by_branch = Loan.group(:branch_number).count
      @revenue_by_branch = Payment.joins(:loan).group('loans.branch_number').sum(:amount)
    end

    def branch_analytics
      authorize_admin

      @branches = Loan.distinct.pluck(:branch_number).sort
      @selected_branch = params[:branch]

      if @selected_branch.present?
        @branch_loans = Loan.where(branch_number: @selected_branch)
        @branch_loan_count = @branch_loans.count
        @branch_active_loans = @branch_loans.where(status: 'active').count
        @branch_completed_loans = @branch_loans.where(status: 'paid').count
        @branch_overdue_loans = @branch_loans.where(status: 'overdue').count
        @branch_total_value = @branch_loans.sum(:total_amount) || 0
        @branch_total_paid = Payment.joins(:loan).where('loans.branch_number': @selected_branch).sum(:amount) || 0
        @branch_remaining_balance = @branch_loans.sum { |loan| loan.remaining_balance }

        # Payment methods in branch
        @branch_payment_methods = Payment.joins(:loan)
                                         .where('loans.branch_number': @selected_branch)
                                         .group(:payment_method)
                                         .sum(:amount)

        # Top customers in branch
        @top_customers_in_branch = Customer.joins(:loans)
                                           .where('loans.branch_number': @selected_branch)
                                           .select('customers.*, COUNT(loans.id) as loan_count')
                                           .group('customers.id')
                                           .order('loan_count DESC')
                                           .limit(10)
      end
    end

    def revenue_report
      authorize_admin

      @date_from = params[:date_from] || 3.months.ago.to_date
      @date_to = params[:date_to] || Date.today

      date_from = Date.parse(@date_from.to_s)
      date_to = Date.parse(@date_to.to_s)

      # Payment statistics
      @total_payments = Payment.where('payment_date >= ? AND payment_date <= ?', date_from, date_to).sum(:amount) || 0
      @verified_amount = Payment.verified.where('payment_date >= ? AND payment_date <= ?', date_from, date_to).sum(:amount) || 0
      @pending_amount = Payment.pending_verification.where('payment_date >= ? AND payment_date <= ?', date_from, date_to).sum(:amount) || 0
      @rejected_amount = Payment.where('verification_status = ? AND payment_date >= ? AND payment_date <= ?', 'rejected', date_from, date_to).sum(:amount) || 0

      # Payment method breakdown
      @payments_by_method = Payment.where('payment_date >= ? AND payment_date <= ?', date_from, date_to)
                                   .group(:payment_method)
                                   .sum(:amount)

      # Daily revenue trend
      @daily_revenue = Payment.where('payment_date >= ? AND payment_date <= ?', date_from, date_to)
                              .group_by { |p| p.payment_date.to_date }
                              .map { |date, payments| [date, payments.sum(&:amount)] }
                              .sort

      # Top collecting agents (by user who created the loan)
      @top_vendors = Payment.joins(:loan)
                            .where('payment_date >= ? AND payment_date <= ?', date_from, date_to)
                            .group('loans.user_id')
                            .select('loans.user_id, users.full_name, COUNT(payments.id) as payment_count, SUM(payments.amount) as total_collected')
                            .joins('INNER JOIN users ON loans.user_id = users.id')
                            .order('total_collected DESC')
                            .limit(10)
    end

    def customer_portfolio
      authorize_admin

      @total_customers = Customer.count
      @active_customers = Customer.where(status: 'active').count
      @suspended_customers = Customer.where(status: 'suspended').count
      @blocked_customers = Customer.where(status: 'blocked').count

      # Customer loan statistics
      @customers_with_loans = Customer.joins(:loans).distinct.count('customers.id')
      @customers_without_loans = Customer.left_joins(:loans).where('loans.id IS NULL').count('customers.id')

      # Portfolio breakdown
      @customers_by_status = Customer.group(:status).count
      @loans_per_customer = Customer.joins(:loans).group('customers.id').count.values.group_by { |x| x }.transform_values(&:count)

      # Risk analysis
      @customers_with_overdue = Customer.joins(:loans).where('loans.status': 'overdue').distinct.count('customers.id')
      @customers_on_time = Customer.left_joins(loans: :installments)
                                   .where('loans.status': 'active')
                                   .where('installments.status != ? OR installments.id IS NULL', 'overdue')
                                   .distinct.count('customers.id')

      # Top customers by loan value
      @top_customers = Customer.joins(:loans)
                              .select('customers.*, SUM(loans.total_amount) as total_loan_value')
                              .group('customers.id')
                              .order('total_loan_value DESC')
                              .limit(15)
    end

    def export_report
      authorize_admin

      report_type = params[:report_type]
      format = params[:format] || 'csv'

      case report_type
      when 'loans'
        export_loans(format)
      when 'payments'
        export_payments(format)
      when 'customers'
        export_customers(format)
      else
        redirect_to admin_reports_path, alert: 'Tipo de reporte no válido'
      end
    end

    private

    def authorize_admin
      redirect_to login_path, alert: 'Acceso denegado' unless current_user&.admin?
    end

    def export_loans(format)
      loans = Loan.all.order(:created_at)

      case format
      when 'csv'
        csv_content = generate_loans_csv(loans)
        send_data csv_content, filename: "loans_export_#{Date.today}.csv", type: 'text/csv'
      else
        redirect_to admin_reports_path, alert: 'Formato no soportado'
      end
    end

    def export_payments(format)
      payments = Payment.all.order(:payment_date)

      case format
      when 'csv'
        csv_content = generate_payments_csv(payments)
        send_data csv_content, filename: "payments_export_#{Date.today}.csv", type: 'text/csv'
      else
        redirect_to admin_reports_path, alert: 'Formato no soportado'
      end
    end

    def export_customers(format)
      customers = Customer.all.order(:created_at)

      case format
      when 'csv'
        csv_content = generate_customers_csv(customers)
        send_data csv_content, filename: "customers_export_#{Date.today}.csv", type: 'text/csv'
      else
        redirect_to admin_reports_path, alert: 'Formato no soportado'
      end
    end

    def generate_loans_csv(loans)
      ::CSV.generate(headers: true) do |csv|
        csv << ['Número de Contrato', 'Cliente', 'Estado', 'Monto Total', 'Monto Pagado', 'Balance', 'Cuotas', 'Fecha de Inicio', 'Sucursal']
        loans.each do |loan|
          csv << [
            loan.contract_number,
            loan.customer.full_name,
            loan.status.titleize,
            loan.total_amount,
            loan.total_paid,
            loan.remaining_balance,
            loan.number_of_installments,
            loan.start_date.strftime('%d/%m/%Y'),
            loan.branch_number
          ]
        end
      end
    end

    def generate_payments_csv(payments)
      ::CSV.generate(headers: true) do |csv|
        csv << ['Fecha de Pago', 'Cliente', 'Contrato', 'Monto', 'Método', 'Estado', 'Referencia']
        payments.each do |payment|
          csv << [
            payment.payment_date.strftime('%d/%m/%Y'),
            payment.loan.customer.full_name,
            payment.loan.contract_number,
            payment.amount,
            payment.payment_method.titleize,
            payment.verification_status.titleize,
            payment.reference_number
          ]
        end
      end
    end

    def generate_customers_csv(customers)
      ::CSV.generate(headers: true) do |csv|
        csv << ['Nombre', 'Identidad', 'Email', 'Teléfono', 'Estado', 'Préstamos Activos', 'Fecha de Creación']
        customers.each do |customer|
          csv << [
            customer.full_name,
            customer.identification_number,
            customer.email,
            customer.phone,
            customer.status.titleize,
            customer.loans.where(status: 'active').count,
            customer.created_at.strftime('%d/%m/%Y')
          ]
        end
      end
    end
  end
end
