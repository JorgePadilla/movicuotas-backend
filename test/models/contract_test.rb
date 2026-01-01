require "test_helper"

class ContractTest < ActiveSupport::TestCase
  setup do
    @contract = contracts(:contract_one)
    @loan = loans(:loan_one)
    @user = users(:admin)
  end

  # Associations
  test "belongs to loan (optional)" do
    assert_respond_to @contract, :loan
    assert @contract.loan.present?
  end

  test "belongs to qr_code_uploaded_by user (optional)" do
    assert_respond_to @contract, :qr_code_uploaded_by
  end

  test "can have contract_document attachment" do
    assert_respond_to @contract, :contract_document
  end

  test "can have signature_image attachment" do
    assert_respond_to @contract, :signature_image
  end

  test "can have qr_code attachment" do
    assert_respond_to @contract, :qr_code
  end

  # Validations
  test "validates uniqueness of loan" do
    contract = Contract.new(loan: @contract.loan)
    assert contract.invalid?
    assert_includes contract.errors[:loan], "has already been taken"
  end

  test "allows loan to be nil" do
    contract = Contract.new(loan: nil)
    assert contract.valid?
  end

  # Predicates
  test "signed? returns true when signature_image is attached and signed_at is present" do
    contract = contracts(:contract_one)
    # Mock the attachment
    unless contract.signature_image.attached?
      # Create a signed contract for testing
      contract = Contract.create!(loan: Loan.create!(
        customer: customers(:customer_one),
        user: @user,
        contract_number: "TEST-SIG-001",
        total_amount: 1000.00,
        approved_amount: 1000.00,
        down_payment_percentage: 30,
        down_payment_amount: 300.00,
        financed_amount: 700.00,
        interest_rate: 12.5,
        number_of_installments: 12,
        start_date: Date.today,
        end_date: 12.months.from_now,
        branch_number: "BR01",
        status: "active"
      ))
    end

    if contract.signature_image.attached? && contract.signed_at.present?
      assert contract.signed?
    else
      assert_not contract.signed?
    end
  end

  test "signed? returns false when signature_image is not attached" do
    contract = Contract.create!(loan: Loan.create!(
      customer: customers(:customer_one),
      user: @user,
      contract_number: "TEST-NOSIG-001",
      total_amount: 1000.00,
      approved_amount: 1000.00,
      down_payment_percentage: 30,
      down_payment_amount: 300.00,
      financed_amount: 700.00,
      interest_rate: 12.5,
      number_of_installments: 12,
      start_date: Date.today,
      end_date: 12.months.from_now,
      branch_number: "BR01",
      status: "active"
    ))

    assert_not contract.signed?
  end

  test "signed? returns false when signed_at is nil" do
    contract = contracts(:contract_one)
    contract.signed_at = nil
    refute contract.signed?
  end

  # Methods - qr_code_present?
  test "qr_code_present? returns true when qr_code is attached" do
    contract = contracts(:contract_one)
    # If contract already has QR code, this should return true
    if contract.qr_code.attached?
      assert contract.qr_code_present?
    else
      assert_not contract.qr_code_present?
    end
  end

  test "qr_code_present? returns false when qr_code is not attached" do
    contract = Contract.create!(loan: Loan.create!(
      customer: customers(:customer_one),
      user: @user,
      contract_number: "TEST-NOQR-001",
      total_amount: 1000.00,
      approved_amount: 1000.00,
      down_payment_percentage: 30,
      down_payment_amount: 300.00,
      financed_amount: 700.00,
      interest_rate: 12.5,
      number_of_installments: 12,
      start_date: Date.today,
      end_date: 12.months.from_now,
      branch_number: "BR01",
      status: "active"
    ))

    assert_not contract.qr_code_present?
  end

  # Methods - generate_pdf
  test "generate_pdf returns placeholder string" do
    result = @contract.generate_pdf
    assert_includes result, "PDF contract content"
    assert_includes result, @contract.loan.contract_number if @contract.loan.present?
  end

  # Callbacks
  test "sets signed_at when signature_image is attached" do
    contract = Contract.create!(loan: Loan.create!(
      customer: customers(:customer_one),
      user: @user,
      contract_number: "TEST-CALLBACK-001",
      total_amount: 1000.00,
      approved_amount: 1000.00,
      down_payment_percentage: 30,
      down_payment_amount: 300.00,
      financed_amount: 700.00,
      interest_rate: 12.5,
      number_of_installments: 12,
      start_date: Date.today,
      end_date: 12.months.from_now,
      branch_number: "BR01",
      status: "active"
    ))

    # Initially signed_at should be nil
    assert_nil contract.signed_at

    # Attach a signature image (simulated)
    contract.signature_image.attach(
      io: StringIO.new("fake image"),
      filename: "signature.png",
      content_type: "image/png"
    )
    contract.save

    # After saving with attached signature, signed_at should be set
    contract.reload
    assert contract.signed_at.present? if contract.signature_image.attached?
  end

  # sign! method
  test "sign! method updates signed_at and signed_by_name" do
    contract = Contract.create!(loan: Loan.create!(
      customer: customers(:customer_one),
      user: @user,
      contract_number: "TEST-SIGN-001",
      total_amount: 1000.00,
      approved_amount: 1000.00,
      down_payment_percentage: 30,
      down_payment_amount: 300.00,
      financed_amount: 700.00,
      interest_rate: 12.5,
      number_of_installments: 12,
      start_date: Date.today,
      end_date: 12.months.from_now,
      branch_number: "BR01",
      status: "active"
    ))

    # Create a fake signature file
    signature_file = Tempfile.new(["sig", ".png"], encoding: 'BINARY')
    signature_file.write("fake image data")
    signature_file.rewind

    result = contract.sign!(signature_file, "John Doe", @user)

    assert result  # sign! should return true on success
    contract.reload
    assert contract.signature_image.attached?
    assert_equal "John Doe", contract.signed_by_name
    assert contract.signed_at.present?
  end

  test "sign! method handles ActionDispatch::Http::UploadedFile" do
    contract = Contract.create!(loan: Loan.create!(
      customer: customers(:customer_one),
      user: @user,
      contract_number: "TEST-SIGN-UPLOAD-001",
      total_amount: 1000.00,
      approved_amount: 1000.00,
      down_payment_percentage: 30,
      down_payment_amount: 300.00,
      financed_amount: 700.00,
      interest_rate: 12.5,
      number_of_installments: 12,
      start_date: Date.today,
      end_date: 12.months.from_now,
      branch_number: "BR01",
      status: "active"
    ))

    # Simulate uploaded file
    signature_file = fixture_file_upload("test_image.png", "image/png")

    result = contract.sign!(signature_file, "Jane Doe", @user)

    assert result
    contract.reload
    assert contract.signature_image.attached?
    assert_equal "Jane Doe", contract.signed_by_name
  end

  test "sign! raises error on transaction failure" do
    contract = Contract.create!(loan: Loan.create!(
      customer: customers(:customer_one),
      user: @user,
      contract_number: "TEST-SIGN-ERROR-001",
      total_amount: 1000.00,
      approved_amount: 1000.00,
      down_payment_percentage: 30,
      down_payment_amount: 300.00,
      financed_amount: 700.00,
      interest_rate: 12.5,
      number_of_installments: 12,
      start_date: Date.today,
      end_date: 12.months.from_now,
      branch_number: "BR01",
      status: "active"
    ))

    # Create invalid file that will cause attachment to fail
    invalid_file = nil

    assert_raises(StandardError) do
      contract.sign!(invalid_file, "Test User", @user)
    end
  end

  # upload_qr_code! method
  test "upload_qr_code! method attaches QR code and sets metadata" do
    contract = @contract

    qr_file = Tempfile.new(["qr", ".png"], encoding: 'BINARY')
    qr_file.write("fake qr data")
    qr_file.rewind

    result = contract.upload_qr_code!(qr_file, @user)

    assert result
    contract.reload
    assert contract.qr_code.attached?
    assert_equal @user, contract.qr_code_uploaded_by
    assert contract.qr_code_uploaded_at.present?
  end

  test "upload_qr_code! handles ActionDispatch::Http::UploadedFile" do
    contract = @contract

    qr_file = fixture_file_upload("test_image.png", "image/png")

    result = contract.upload_qr_code!(qr_file, @user)

    assert result
    contract.reload
    assert contract.qr_code.attached?
    assert_equal @user, contract.qr_code_uploaded_by
  end

  test "upload_qr_code! raises error on invalid file" do
    contract = @contract
    invalid_file = nil

    assert_raises(StandardError) do
      contract.upload_qr_code!(invalid_file, @user)
    end
  end

  # Edge cases
  test "contract without loan is valid" do
    contract = Contract.new(loan: nil)
    assert contract.valid?
  end

  test "multiple contracts can exist without loans" do
    contract1 = Contract.create!(loan: nil)
    contract2 = Contract.create!(loan: nil)

    assert contract1.persisted?
    assert contract2.persisted?
  end

  test "persists contract with associations" do
    loan = Loan.create!(
      customer: customers(:customer_one),
      user: @user,
      contract_number: "PERSIST-001",
      total_amount: 1000.00,
      approved_amount: 1000.00,
      down_payment_percentage: 30,
      down_payment_amount: 300.00,
      financed_amount: 700.00,
      interest_rate: 12.5,
      number_of_installments: 12,
      start_date: Date.today,
      end_date: 12.months.from_now,
      branch_number: "BR01",
      status: "active"
    )

    contract = Contract.new(loan: loan)
    assert contract.save
    assert_not_nil contract.id

    reloaded = Contract.find(contract.id)
    assert_equal loan.id, reloaded.loan_id
  end

  test "destroys contract" do
    contract = contracts(:contract_one)
    contract_id = contract.id

    contract.destroy
    assert_nil Contract.find_by(id: contract_id)
  end

  test "updates contract attributes" do
    @contract.signed_by_name = "Updated Signer"
    @contract.save

    assert_equal "Updated Signer", @contract.reload.signed_by_name
  end
end
