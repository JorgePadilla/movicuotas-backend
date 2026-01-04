require "test_helper"

module Vendor
  class ContractsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers rescue nil

    setup do
      # Load seed data for test (if not already loaded)
      begin
        load "#{Rails.root}/db/seeds.rb" if Rails.env.test?
      rescue IOError
        # File already loaded or closed, ignore
      end

      @contract = Contract.first
      @loan = @contract.loan
      @vendor = User.find_by(email: 'supervisor@movicuotas.com')
    end

    test "should get show when authenticated as vendor" do
      post login_url, params: { email: @vendor.email, password: 'password123' }
      assert_redirected_to vendor_customer_search_path
      follow_redirect!

      get vendor_contract_path(@contract, loan_id: @loan.id)
      assert_response :success
      assert_select 'h1', 'Contrato de Crédito'
      assert_select '.contract-number', @loan.contract_number
    end

    test "should redirect to login when not authenticated" do
      get vendor_contract_path(@contract)
      assert_redirected_to login_path
      assert_equal 'Debes iniciar sesión', flash[:alert]
    end

    test "should get signature page when authenticated" do
      post login_url, params: { email: @vendor.email, password: 'password123' }
      follow_redirect!

      get signature_vendor_contract_path(@contract)
      assert_response :success
      assert_select 'h1', 'Firma Digital'
      assert_select 'canvas[data-signature-target="canvas"]'
    end

    test "should save signature when authenticated" do
      post login_url, params: { email: @vendor.email, password: 'password123' }
      follow_redirect!

      # Create a fake signature data (base64 PNG)
      fake_signature = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIwAAAABJRU5ErkJggg=='

      assert_changes -> { @contract.reload.signature_image.attached? }, from: false, to: true do
        post save_signature_vendor_contract_path(@contract), params: { signature_data: fake_signature }
      end

      assert_redirected_to success_vendor_contract_path(@contract)
      assert_equal 'Firma guardada exitosamente. ¡Crédito aplicado!', flash[:notice]
    end

    test "should get success page after signature" do
      post login_url, params: { email: @vendor.email, password: 'password123' }
      follow_redirect!

      get success_vendor_contract_path(@contract)
      assert_response :success
      assert_select 'h1', '¡Crédito Aplicado!'
      assert_select 'a', 'Descargar Contrato'
      assert_select 'a', 'Proceder a Configuración de Teléfono'
    end

    test "should download PDF when authenticated" do
      post login_url, params: { email: @vendor.email, password: 'password123' }
      follow_redirect!

      get download_vendor_contract_path(@contract)
      assert_response :success
      assert_equal 'application/pdf', response.content_type
      assert_match /attachment; filename="contrato-.*\.pdf"/, response.headers['Content-Disposition']
    end

    test "should not allow cobrador to create contract" do
      cobrador = User.find_by(email: 'cobrador@movicuotas.com')
      post login_url, params: { email: cobrador.email, password: 'password123' }
      follow_redirect!

      # Cobrador can view but not create
      get vendor_contract_path(@contract)
      assert_response :success

      # Attempt to create new contract (should redirect)
      post vendor_contracts_path, params: { loan_id: @loan.id }
      assert_redirected_to vendor_customer_search_path
      assert flash[:alert].present?
    end
  end
end