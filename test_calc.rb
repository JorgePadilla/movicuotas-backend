# Test calculator against table values
require 'date'
require_relative 'app/services/biweekly_calculator_service'

# Test case from table: phone price 3500, down payment 30%, 12 installments, age 24
dob = Date.new(Date.today.year - 24, Date.today.month, Date.today.day)
calculator = BiweeklyCalculatorService.new(
  phone_price: 3500,
  down_payment_percentage: 30,
  number_of_installments: 12,
  date_of_birth: dob
)

if calculator.valid?
  result = calculator.calculate
  puts '=== Calculator Test ==='
  puts "Phone price: #{result[:phone_price]}"
  puts "Down payment %: #{result[:down_payment_percentage]}"
  puts "Down payment amount: #{result[:down_payment_amount]}"
  puts "Financed amount: #{result[:financed_amount]}"
  puts "Bi-weekly rate: #{result[:bi_weekly_rate_percentage]}% (decimal: #{result[:bi_weekly_rate]})"
  puts "Number of installments: #{result[:number_of_installments]}"
  puts "Installment amount: #{result[:installment_amount]}"
  puts "Expected: 404.7261306"
  puts "Difference: #{result[:installment_amount] - 404.7261306}"
  puts "Age group: #{result[:age_group]}"
  
  # Manual calculation for verification
  puts "\n=== Manual Calculation ==="
  p = 2450.0  # financed amount
  r = 0.125   # 12.5% biweekly rate
  n = 12.0    # installments
  
  # PMT = P * (r(1+r)^n) / ((1+r)^n - 1)
  numerator = r * (1 + r) ** n
  denominator = (1 + r) ** n - 1
  pmt = p * (numerator / denominator)
  puts "Manual PMT: #{pmt}"
  puts "Rounded PMT: #{pmt.round(2)}"
  puts "Service PMT rounded: #{result[:installment_amount]}"
else
  puts 'Calculator invalid:'
  puts calculator.errors
end
