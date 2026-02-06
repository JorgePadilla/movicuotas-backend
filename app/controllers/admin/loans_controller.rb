# frozen_string_literal: true

module Admin
  class LoansController < ApplicationController
    include Sortable
    before_action :set_loan, only: [ :show, :destroy ]

    def index
      set_sort_params(
        allowed_columns: %w[contract_number customer_name branch_number total_amount status created_at],
        default_column: "created_at"
      )

      column_mapping = {
        "contract_number" => "loans.contract_number",
        "customer_name" => "customers.full_name",
        "branch_number" => "loans.branch_number",
        "total_amount" => "loans.total_amount",
        "status" => "loans.status",
        "created_at" => "loans.created_at"
      }
      @loans = policy_scope(Loan).left_joins(:customer).order(sort_order_sql(column_mapping))

      # Filter by status if provided
      @loans = @loans.where(status: params[:status]) if params[:status].present?

      # Filter by branch if provided
      @loans = @loans.where(branch_number: params[:branch]) if params[:branch].present?

      # Search by contract number or customer name
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        @loans = @loans.joins(:customer)
                       .where("loans.contract_number ILIKE ? OR customers.full_name ILIKE ? OR customers.identification_number ILIKE ?", search_term, search_term, search_term)
                       .distinct
      end

      # Get unique branches for filtering
      @branches = Loan.distinct.pluck(:branch_number).sort

      # Paginate results (20 per page)
      @loans = @loans.page(params[:page]).per(20)
    end

    def show
      authorize @loan
    end

    def destroy
      authorize @loan
      @loan.destroy
      redirect_to admin_loans_path, notice: "Préstamo eliminado exitosamente."
    end

    private

    def set_loan
      @loan = Loan.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_loans_path, alert: "Préstamo no encontrado."
    end
  end
end
