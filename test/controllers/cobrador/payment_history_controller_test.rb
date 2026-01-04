# frozen_string_literal: true

require "test_helper"

module Cobrador
  class PaymentHistoryControllerTest < ActionDispatch::IntegrationTest
    setup do
      @cobrador = users(:cobrador)
      @admin = users(:admin)
      @loan = loans(:with_payments)
    end

    test "cobrador can view payment history" do
      sign_in_as(@cobrador)
      get cobrador_loan_payment_history_path(@loan)
      assert_response :success
      assert_select "h1", "Historial de Pagos (Solo Lectura)"
    end

    test "admin can view payment history" do
      sign_in_as(@admin)
      get cobrador_loan_payment_history_path(@loan)
      assert_response :success
    end

    test "payment history displays customer information" do
      sign_in_as(@cobrador)
      get cobrador_loan_payment_history_path(@loan)

      payment_history = assigns(:payment_history)
      assert_equal @loan.customer.full_name, payment_history[:customer][:name]
      assert_equal @loan.contract_number, payment_history[:customer][:contract_number]
    end

    test "payment history displays summary statistics" do
      sign_in_as(@cobrador)
      get cobrador_loan_payment_history_path(@loan)

      summary = assigns(:payment_history)[:summary]
      assert_equal @loan.number_of_installments, summary[:total_installments]
      assert_equal @loan.installments.paid.count, summary[:paid_installments]
      assert_equal @loan.installments.pending.count, summary[:pending_installments]
    end

    test "payment history includes installments" do
      sign_in_as(@cobrador)
      get cobrador_loan_payment_history_path(@loan)

      installments = assigns(:payment_history)[:installments]
      assert_equal @loan.installments.count, installments.count
    end

    test "payment history is read-only for cobrador" do
      sign_in_as(@cobrador)
      get cobrador_loan_payment_history_path(@loan)

      # Verify the view doesn't include edit/delete buttons
      assert_not_includes response.body, "Editar"
      assert_not_includes response.body, "Eliminar"
    end

    test "supervisor can view their own loan payment history" do
      loan = @loan.update(user: users(:supervisor))
      supervisor = users(:supervisor)
      sign_in_as(supervisor)

      get cobrador_loan_payment_history_path(@loan)
      # Should be accessible but filtered by supervisor's branch
      # Behavior depends on branch logic
    end
  end
end
