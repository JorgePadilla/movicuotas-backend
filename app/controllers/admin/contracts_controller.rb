# frozen_string_literal: true

module Admin
  class ContractsController < ApplicationController
    before_action :set_contract, only: [ :show ]
    after_action :verify_authorized, except: [ :index ]

    # Admin contracts index with filtering and search
    def index
      @contracts = policy_scope(Contract)
      @contracts = @contracts.joins(:loan).where("loans.contract_number ILIKE ?", "%#{params[:search]}%") if params[:search].present?
      @contracts = @contracts.order(created_at: :desc).page(params[:page]).per(25)
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
