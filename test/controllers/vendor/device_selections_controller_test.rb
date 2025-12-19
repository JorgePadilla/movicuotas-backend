require "test_helper"

module Vendor
  class DeviceSelectionsControllerTest < ActionDispatch::IntegrationTest

    setup do
      # Use seeded data
      @vendor = User.find_by(email: "vendedor@movicuotas.com")
      @credit_application = CreditApplication.approved.first
      # Find a phone model with price <= approved_amount
      @phone_model = PhoneModel.active.where("price <= ?", @credit_application.approved_amount).first
      # Ensure we have a phone model for testing
      if @phone_model.nil?
        # Create a phone model within approved amount for testing
        @phone_model = PhoneModel.create!(
          brand: "TestBrand",
          model: "TestModel",
          storage: "128",
          color: "Black",
          price: @credit_application.approved_amount,
          active: true
        )
      end
    end

    teardown do
      # Clean up created phone model if it's the test one
      if @phone_model.brand == "TestBrand"
        @phone_model.destroy
      end
    end

    test "should get show when logged in as vendor and credit application approved" do
      # Log in as vendor
      post login_url, params: { email: @vendor.email, password: "password123" }

      get vendor_device_selection_url(@credit_application)
      assert_response :success
      assert_select "h1", "Catálogo de Teléfonos"
      assert_select "input[type='radio'][name='credit_application[selected_phone_model_id]']"
    end

    test "should redirect if not logged in" do
      get vendor_device_selection_url(@credit_application)
      assert_redirected_to login_path
      assert_equal "Debes iniciar sesión", flash[:alert]
    end

    test "should redirect if credit application not approved" do
      post login_url, params: { email: @vendor.email, password: "password123" }
      pending_app = CreditApplication.pending.first
      get vendor_device_selection_url(pending_app)
      assert_redirected_to vendor_customer_search_path
      assert_match /no está aprobada/, flash[:alert]
    end

    test "should update with valid phone selection" do
      post login_url, params: { email: @vendor.email, password: "password123" }

      patch vendor_device_selection_url(@credit_application), params: {
        credit_application: {
          selected_phone_model_id: @phone_model.id,
          selected_imei: "123456789012345",
          selected_color: "Negro"
        }
      }

      assert_redirected_to vendor_device_selection_confirmation_path(@credit_application)
      assert_equal "Teléfono seleccionado correctamente. Proceda a confirmación.", flash[:notice]

      @credit_application.reload
      assert_equal @phone_model.id, @credit_application.selected_phone_model_id
      assert_equal "123456789012345", @credit_application.selected_imei
      assert_equal "Negro", @credit_application.selected_color
    end

    test "should not update with phone price exceeding approved amount" do
      post login_url, params: { email: @vendor.email, password: "password123" }
      expensive_phone = PhoneModel.active.where("price > ?", @credit_application.approved_amount).first
      # If no expensive phone, create one
      if expensive_phone.nil?
        expensive_phone = PhoneModel.create!(
          brand: "Expensive",
          model: "Phone",
          storage: "512",
          color: "Gold",
          price: @credit_application.approved_amount + 1000,
          active: true
        )
      end

      patch vendor_device_selection_url(@credit_application), params: {
        credit_application: {
          selected_phone_model_id: expensive_phone.id,
          selected_imei: "123456789012345",
          selected_color: "Negro"
        }
      }

      assert_response :unprocessable_entity
      assert_select "div.text-red-800", /excede el monto aprobado/
      @credit_application.reload
      assert_nil @credit_application.selected_phone_model_id

      # Clean up if created
      if expensive_phone.brand == "Expensive"
        expensive_phone.destroy
      end
    end

    test "should not update with invalid IMEI" do
      post login_url, params: { email: @vendor.email, password: "password123" }

      patch vendor_device_selection_url(@credit_application), params: {
        credit_application: {
          selected_phone_model_id: @phone_model.id,
          selected_imei: "123", # Too short
          selected_color: "Negro"
        }
      }

      assert_response :unprocessable_entity
      assert_select "div.text-red-800", /debe tener 15 dígitos/
    end

    test "should get confirmation after device selection" do
      post login_url, params: { email: @vendor.email, password: "password123" }
      # First select a phone
      @credit_application.update!(
        selected_phone_model_id: @phone_model.id,
        selected_imei: "123456789012345",
        selected_color: "Negro"
      )

      get vendor_device_selection_confirmation_url(@credit_application)
      assert_response :success
      assert_select "h1", "Confirmación de Compra"
      assert_select "h4", @phone_model.brand
    end

    test "should redirect from confirmation if no device selected" do
      post login_url, params: { email: @vendor.email, password: "password123" }
      # Ensure no selection
      @credit_application.update!(selected_phone_model_id: nil, selected_imei: nil, selected_color: nil)

      get vendor_device_selection_confirmation_url(@credit_application)
      assert_redirected_to vendor_device_selection_path(@credit_application)
      assert_match /Primero debe seleccionar/, flash[:alert]
    end
  end
end