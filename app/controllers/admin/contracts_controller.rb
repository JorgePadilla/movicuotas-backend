# frozen_string_literal: true

module Admin
  class ContractsController < ApplicationController
    include Sortable
    before_action :set_contract, only: [ :show ]
    after_action :verify_authorized, except: [ :index ]

    # Admin contracts index with filtering and search
    def index
      set_sort_params(
        allowed_columns: %w[created_at contract_number status],
        default_column: "created_at"
      )

      column_mapping = {
        "created_at" => "contracts.created_at",
        "contract_number" => "loans.contract_number",
        "status" => "contracts.status"
      }
      @contracts = policy_scope(Contract).left_joins(:loan)
      @contracts = @contracts.where("loans.contract_number ILIKE ?", "%#{params[:search]}%") if params[:search].present?
      @contracts = @contracts.order(sort_order_sql(column_mapping)).page(params[:page]).per(25)
    end

    # View contract details
    def show
      authorize @contract
    end

    private

    def set_contract
      @contract = Contract.find(params[:id])
      @loan = @contract.loan
      @customer = @loan&.customer
      @credit_application = @loan&.credit_application
    end
  end
end
