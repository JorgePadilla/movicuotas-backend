# frozen_string_literal: true

module Admin
  class LoansController < ApplicationController
    before_action :set_loan, only: [:show]

    def index
      @loans = policy_scope(Loan).order(created_at: :desc)

      # Filter by status if provided
      @loans = @loans.where(status: params[:status]) if params[:status].present?

      # Filter by branch if provided
      @loans = @loans.where(branch_number: params[:branch]) if params[:branch].present?

      # Search by contract number or customer name
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        @loans = @loans.joins(:customer)
                       .where("loans.contract_number ILIKE ? OR customers.full_name ILIKE ?", search_term, search_term)
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

    private

    def set_loan
      @loan = Loan.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_loans_path, alert: "Préstamo no encontrado."
    end
  end
end
