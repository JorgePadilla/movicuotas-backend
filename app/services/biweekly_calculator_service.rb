# Service to calculate bi-weekly loan installments for MOVICUOTAS vendor workflow
# Step 12: Payment Calculator
#
# Business Rules:
# - Down payment options: 30%, 40%, 50% only
# - Installment terms: 6, 8, 10, or 12 bi-weekly periods only
# - Interest rates from table (bi-weekly rates, not annual)
# - Age restrictions: 21-60 years only
#   - 50-60 years: Only 40% and 50% down payment, max financed L. 3,000
#   - 21-49 years: All options, max financed L. 3,500
# - Bi-weekly payments (every 14 days)
# - Phone price only (no accessories)
#
# Calculation Formula:
# PMT = P * (r(1+r)^n) / ((1+r)^n - 1)
# Where:
#   P = financed_amount (total_amount - down_payment)
#   r = bi_weekly_rate (from table, as decimal)
#   n = number_of_installments
class BiweeklyCalculatorService
  # Valid down payment percentages (from Loan model validation)
  VALID_DOWN_PAYMENT_PERCENTAGES = [ 30, 40, 50 ].freeze

  # Valid installment terms (updated to include 10)
  VALID_INSTALLMENT_TERMS = [ 6, 8, 10, 12 ].freeze

  # Interest Rate Table (Bi-weekly Rates)
  # Source: CLAUDE.md - Payment Calculator Reference Data
  RATE_TABLE = {
    30 => { 6 => 14.0, 8 => 13.5, 10 => 13.0, 12 => 12.5 },
    40 => { 6 => 13.0, 8 => 12.5, 10 => 12.0, 12 => 11.5 },
    50 => { 6 => 12.0, 8 => 11.5, 10 => 11.0, 12 => 10.5 }
  }.freeze

  # Age restrictions
  MIN_AGE = 21
  MAX_AGE = 60
  AGE_GROUP_1_MIN = 21  # 21-49 years
  AGE_GROUP_1_MAX = 49
  AGE_GROUP_2_MIN = 50  # 50-60 years
  AGE_GROUP_2_MAX = 60

  # Max financed amounts by age group
  MAX_FINANCED_AGE_GROUP_1 = 3_500.00  # 21-49 years
  MAX_FINANCED_AGE_GROUP_2 = 3_000.00  # 50-60 years

  attr_reader :phone_price, :down_payment_percentage, :number_of_installments,
              :date_of_birth, :age, :bi_weekly_rate, :start_date, :errors

  # Initialize with calculator parameters
  # @param phone_price [Numeric] Total phone price (no accessories)
  # @param down_payment_percentage [Integer] 30, 40, or 50
  # @param number_of_installments [Integer] 6, 8, 10, or 12
  # @param date_of_birth [Date] Customer's date of birth (required for age validation)
  # @param start_date [Date] Loan start date for installment schedule (default: today)
  def initialize(
    phone_price:,
    down_payment_percentage:,
    number_of_installments:,
    date_of_birth:,
    start_date: Date.today
  )
    @phone_price = phone_price.to_f
    @down_payment_percentage = down_payment_percentage.to_i
    @number_of_installments = number_of_installments.to_i
    @errors = []

    # Parse date of birth with validation
    begin
      if date_of_birth.nil? || date_of_birth.to_s.strip.empty?
        @errors << "Fecha de nacimiento requerida"
        @date_of_birth = nil
      else
        @date_of_birth = date_of_birth.is_a?(Date) ? date_of_birth : Date.parse(date_of_birth.to_s)
      end
    rescue Date::Error => e
      @errors << "Fecha de nacimiento inválida: #{date_of_birth}"
      @date_of_birth = nil
    end

    # Parse start date
    begin
      @start_date = start_date.is_a?(Date) ? start_date : Date.parse(start_date.to_s)
    rescue Date::Error => e
      @errors << "Fecha de inicio inválida: #{start_date}"
      @start_date = Date.today
    end

    # Calculate age
    @age = calculate_age

    # Get bi-weekly rate from table
    @bi_weekly_rate = get_rate_from_table

    validate_parameters
  end

  # Calculate bi-weekly installment amount and schedule
  # @return [Hash] Calculation results including installment amount and schedule
  #   {
  #     success: true/false,
  #     installment_amount: 1234.56,
  #     down_payment_amount: 1234.56,
  #     financed_amount: 1234.56,
  #     total_interest: 123.45,
  #     total_payment: 12345.67,
  #     bi_weekly_rate: 0.125, # decimal
  #     installments: [...],
  #     errors: [...]
  #   }
  def calculate
    return { success: false, errors: @errors } unless valid?

    begin
      installment_amount = calculate_installment_amount
      schedule = generate_installment_schedule(installment_amount)

      {
        success: true,
        installment_amount: installment_amount.round(2),
        down_payment_amount: down_payment_amount.round(2),
        financed_amount: financed_amount.round(2),
        total_interest: (installment_amount * @number_of_installments - financed_amount).round(2),
        total_payment: (down_payment_amount + (installment_amount * @number_of_installments)).round(2),
        bi_weekly_rate: @bi_weekly_rate,
        bi_weekly_rate_percentage: (@bi_weekly_rate * 100).round(1),
        installments: schedule,
        down_payment_percentage: @down_payment_percentage,
        number_of_installments: @number_of_installments,
        phone_price: @phone_price.round(2),
        age: @age,
        age_group: age_group
      }
    rescue StandardError => e
      @errors << "Error en cálculo: #{e.message}"
      { success: false, errors: @errors }
    end
  end

  # Quick calculation of just the installment amount (without full schedule)
  # @return [Numeric, nil] Installment amount or nil if invalid
  def installment_amount
    return unless valid?
    calculate_installment_amount.round(2)
  end

  # Calculate down payment amount
  # @return [Numeric]
  def down_payment_amount
    @phone_price * (@down_payment_percentage / 100.0)
  end

  # Calculate financed amount (amount to be paid in installments)
  # @return [Numeric]
  def financed_amount
    @phone_price - down_payment_amount
  end

  # Determine age group (1: 21-49, 2: 50-60)
  # @return [Integer, nil] 1 or 2, or nil if outside range
  def age_group
    return nil if @age.nil?
    return 1 if @age.between?(AGE_GROUP_1_MIN, AGE_GROUP_1_MAX)
    return 2 if @age.between?(AGE_GROUP_2_MIN, AGE_GROUP_2_MAX)
    nil
  end

  # Check if parameters are valid
  # @return [Boolean]
  def valid?
    @errors.empty?
  end

  private

  # Validate all input parameters
  def validate_parameters
    validate_phone_price
    validate_down_payment_percentage
    validate_number_of_installments
    validate_age
    validate_age_restrictions
    validate_financed_amount_limit
    validate_start_date
  end

  def validate_phone_price
    if @phone_price <= 0
      @errors << "El precio del teléfono debe ser mayor que cero"
    elsif @phone_price > 1_000_000 # Reasonable upper limit
      @errors << "El precio del teléfono excede el límite máximo"
    end
  end

  def validate_down_payment_percentage
    unless VALID_DOWN_PAYMENT_PERCENTAGES.include?(@down_payment_percentage)
      @errors << "Porcentaje de inicial inválido. Debe ser 30%, 40% o 50%"
    end
  end

  def validate_number_of_installments
    unless VALID_INSTALLMENT_TERMS.include?(@number_of_installments)
      @errors << "Plazo de cuotas inválido. Debe ser 6, 8, 10 o 12 cuotas quincenales"
    end
  end

  def validate_age
    return if @age.nil?  # Already validated in initialize

    if @age < MIN_AGE
      @errors << "El cliente debe tener al menos #{MIN_AGE} años para obtener crédito"
    elsif @age > MAX_AGE
      @errors << "El cliente no puede tener más de #{MAX_AGE} años para obtener crédito"
    end
  end

  def validate_age_restrictions
    return unless age_group == 2  # 50-60 years

    # 50-60 years: only 40% and 50% down payment allowed
    unless [ 40, 50 ].include?(@down_payment_percentage)
      @errors << "Clientes de 50-60 años solo pueden seleccionar 40% o 50% de pago inicial"
    end
  end

  def validate_financed_amount_limit
    return unless age_group

    max_amount = age_group == 1 ? MAX_FINANCED_AGE_GROUP_1 : MAX_FINANCED_AGE_GROUP_2

    if financed_amount > max_amount
      @errors << "Monto financiado excede el límite para la edad del cliente (L. #{max_amount})"
    end
  end

  def validate_start_date
    if @start_date < Date.today
      @errors << "La fecha de inicio no puede ser en el pasado"
    end
  end

  # Calculate age from date of birth
  def calculate_age
    return nil if @date_of_birth.nil?

    today = Date.today
    age = today.year - @date_of_birth.year
    age -= 1 if today.yday < @date_of_birth.yday
    age
  end

  # Get bi-weekly rate from table based on down payment and installments
  # @return [Float] Rate as decimal (e.g., 0.125 for 12.5%)
  def get_rate_from_table
    RATE_TABLE[@down_payment_percentage]&.[](@number_of_installments)&./ 100.0
  end

  # Calculate bi-weekly installment amount using amortization formula
  # PMT = P * (r(1+r)^n) / ((1+r)^n - 1)
  # Where:
  #   P = financed_amount
  #   r = bi_weekly_rate (as decimal)
  #   n = number_of_installments
  def calculate_installment_amount
    p = financed_amount
    r = @bi_weekly_rate
    n = @number_of_installments

    # Handle zero interest rate (should not happen with rate table)
    return p / n if r.zero?

    # PMT = P * (r(1+r)^n) / ((1+r)^n - 1)
    numerator = r * (1 + r) ** n
    denominator = (1 + r) ** n - 1

    p * (numerator / denominator)
  end

  # Generate installment schedule with due dates
  # @param installment_amount [Numeric] Calculated installment amount
  # @return [Array<Hash>] Installment schedule with due dates and amounts
  def generate_installment_schedule(installment_amount)
    schedule = []

    @number_of_installments.times do |i|
      due_date = @start_date + (i * 14).days

      schedule << {
        installment_number: i + 1,
        due_date: due_date,
        amount: installment_amount.round(2),
        status: "pending"
      }
    end

    schedule
  end
end
