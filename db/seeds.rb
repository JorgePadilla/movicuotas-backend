# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Only seed in development, test, and production environments
if Rails.env.development? || Rails.env.test? || Rails.env.production?
  # Clear existing data only in development and test (optional - comment out if you want to preserve data)
  if Rails.env.development? || Rails.env.test?
    puts "Clearing existing data..."
    # Uncomment the following lines to clear data before seeding
    PaymentInstallment.delete_all
    Payment.delete_all
    Installment.delete_all
    MdmBlueprint.delete_all
    Device.delete_all
    Contract.delete_all
    Notification.delete_all
    Loan.delete_all
    CreditApplication.delete_all
    Customer.delete_all
    PhoneModel.delete_all
    AuditLog.delete_all
    Session.delete_all
    User.delete_all
  end

  puts "Seeding data..."

# 1. Create Users
puts "Creating users..."
admin = User.find_or_create_by!(email: 'admin@movicuotas.com') do |user|
  user.full_name = 'Administrador Principal'
  user.password = 'password123'
  user.role = 'admin'
  user.branch_number = 'S01'
  user.active = true
end

# Admin user with specified credentials
admin_jorge = User.find_or_create_by!(email: 'jorgep4dill4@gmail.com') do |user|
  user.full_name = 'Jorge Padilla'
  user.password = 'Honduras1!'
  user.role = 'admin'
  user.branch_number = 'S01'
  user.active = true
end

vendedor = User.find_or_create_by!(email: 'vendedor@movicuotas.com') do |user|
  user.full_name = 'Vendedor Ejemplo'
  user.password = 'password123'
  user.role = 'vendedor'
  user.branch_number = 'S01'
  user.active = true
end

cobrador = User.find_or_create_by!(email: 'cobrador@movicuotas.com') do |user|
  user.full_name = 'Cobrador Ejemplo'
  user.password = 'password123'
  user.role = 'cobrador'
  user.branch_number = 'S01'
  user.active = true
end

# New admin user with movicuotas email
movicuotas_admin = User.find_or_create_by!(email: 'movicuotas@gmail.com') do |user|
  user.full_name = 'MOVICUOTAS Admin'
  user.password = 'Honduras123!'
  user.role = 'admin'
  user.branch_number = 'S01'
  user.active = true
end

# 2. Create Phone Models
puts "Creating phone models..."
phone_models = [
  {
    brand: 'Apple',
    model: 'iPhone 15 Pro',
    storage: '256GB',
    color: 'Titanio Natural',
    price: 25_000.00,
    active: true
  },
  {
    brand: 'Samsung',
    model: 'Galaxy S24 Ultra',
    storage: '512GB',
    color: 'Negro',
    price: 22_000.00,
    active: true
  },
  {
    brand: 'Xiaomi',
    model: 'Redmi Note 13 Pro',
    storage: '128GB',
    color: 'Azul',
    price: 8_500.00,
    active: true
  },
  {
    brand: 'Motorola',
    model: 'Edge 40',
    storage: '256GB',
    color: 'Verde',
    price: 12_000.00,
    active: true
  },
  {
    brand: 'Huawei',
    model: 'P60 Pro',
    storage: '256GB',
    color: 'Blanco',
    price: 18_500.00,
    active: true
  },
  {
    brand: 'Samsung',
    model: 'A16 128GB',
    storage: '128GB',
    color: 'Negro',
    price: 4_500.00,
    active: true
  },
  {
    brand: 'Samsung',
    model: 'A07 128GB',
    storage: '128GB',
    color: 'Negro',
    price: 4_000.00,
    active: true
  },
  {
    brand: 'Samsung',
    model: 'A07 64GB',
    storage: '64GB',
    color: 'Negro',
    price: 3_500.00,
    active: true
  },
  {
    brand: 'Samsung',
    model: 'A06 128GB',
    storage: '128GB',
    color: 'Negro',
    price: 3_500.00,
    active: true
  },
  {
    brand: 'Samsung',
    model: 'A06 64GB',
    storage: '64GB',
    color: 'Negro',
    price: 3_000.00,
    active: true
  }
]

phone_models.each do |attrs|
  PhoneModel.find_or_create_by!(brand: attrs[:brand], model: attrs[:model]) do |pm|
    pm.storage = attrs[:storage]
    pm.color = attrs[:color]
    pm.price = attrs[:price]
    pm.active = attrs[:active]
  end
end

# 3. Create Customers
puts "Creating customers..."
customers = [
  {
    identification_number: '0801199012345',
    full_name: 'Juan Pérez García',
    gender: 'male',
    date_of_birth: Date.new(1990, 5, 15),
    address: 'Colonia Los Robles, Tegucigalpa',
    city: 'Tegucigalpa',
    department: 'Francisco Morazán',
    phone: '98765432',
    email: 'juan.perez@example.com',
    status: 'active'
  },
  {
    identification_number: '0801198567890',
    full_name: 'María Rodríguez López',
    gender: 'female',
    date_of_birth: Date.new(1985, 8, 22),
    address: 'Residencial Valle Verde, San Pedro Sula',
    city: 'San Pedro Sula',
    department: 'Cortés',
    phone: '87654321',
    email: 'maria.rodriguez@example.com',
    status: 'active'
  },
  {
    identification_number: '0801199554321',
    full_name: 'Carlos Hernández Martínez',
    gender: 'male',
    date_of_birth: Date.new(1995, 3, 10),
    address: 'Barrio Abajo, La Ceiba',
    city: 'La Ceiba',
    department: 'Atlántida',
    phone: '76543210',
    email: 'carlos.hernandez@example.com',
    status: 'active'
  }
]

customers.each do |attrs|
  Customer.find_or_create_by!(identification_number: attrs[:identification_number]) do |c|
    c.full_name = attrs[:full_name]
    c.gender = attrs[:gender]
    c.date_of_birth = attrs[:date_of_birth]
    c.address = attrs[:address]
    c.city = attrs[:city]
    c.department = attrs[:department]
    c.phone = attrs[:phone]
    c.email = attrs[:email]
    c.status = attrs[:status]
  end
end

# 4. Create a Credit Application (approved)
puts "Creating credit application..."
customer = Customer.first
if customer
  credit_app = CreditApplication.find_or_create_by!(application_number: 'APP-20251216-000001') do |ca|
    ca.customer = customer
    ca.vendor = vendedor
    ca.status = 'approved'
    ca.approved_amount = 22_000.00
    ca.employment_status = 'employed'
    ca.salary_range = 'range_20000_30000'
    ca.verification_method = 'sms'
  end
end

# 5. Create a Loan (active)
puts "Creating loan..."
if customer
  loan = Loan.find_or_create_by!(contract_number: 'S01-2025-12-16-000001') do |l|
    l.customer = customer
    l.user = vendedor
    l.branch_number = 'S01'
    l.status = 'active'
    l.total_amount = 22_000.00
    l.approved_amount = 22_000.00
    l.down_payment_percentage = 30.0
    l.down_payment_amount = 6_600.00
    l.financed_amount = 15_400.00
    l.interest_rate = 12.5
    l.number_of_installments = 12
    l.start_date = Date.today
    l.end_date = Date.today + 12 * 14  # 12 bi-weekly periods (14 days each)
  end

  # 6. Create Installments (bi-weekly)
  puts "Creating installments..."
  if loan.installments.empty?
    (1..loan.number_of_installments).each do |i|
      due_date = loan.start_date + (i * 14)  # bi-weekly
      amount = (loan.financed_amount * (1 + loan.interest_rate / 100.0)) / loan.number_of_installments

      Installment.create!(
        loan: loan,
        installment_number: i,
        due_date: due_date,
        amount: amount.round(2),
        status: i == 1 ? 'pending' : 'pending'
      )
    end
  end

  # 7. Create Device
  puts "Creating device..."
  phone_model = PhoneModel.second  # Samsung Galaxy S24 Ultra
  device = Device.find_or_create_by!(imei: '123456789012345') do |d|
    d.loan = loan
    d.phone_model = phone_model
    d.brand = phone_model.brand
    d.model = phone_model.model
    d.color = 'Negro'
    d.lock_status = 'unlocked'
  end

  # 8. Create Contract
  puts "Creating contract..."
  contract = Contract.find_or_create_by!(loan: loan) do |c|
    c.signed_at = Time.current
    c.signed_by_name = customer.full_name
  end

  # 9. Create MdmBlueprint
  puts "Creating MDM blueprint..."
  MdmBlueprint.find_or_create_by!(device: device) do |mb|
    mb.qr_code_data = '{"device_id":' + device.id.to_s + ',"imei":"' + device.imei + '"}'
    mb.status = 'active'
    mb.generated_at = Time.current
  end

  # 10. Create a Payment (first installment)
  puts "Creating payment..."
  first_installment = loan.installments.first
  if first_installment
    payment = Payment.find_or_create_by!(reference_number: 'PAY-001') do |p|
      p.loan = loan
      p.amount = first_installment.amount
      p.payment_date = Date.today
      p.payment_method = 'cash'
      p.verification_status = 'verified'
    end

    # Link payment to installment
    PaymentInstallment.find_or_create_by!(payment: payment, installment: first_installment) do |pi|
      pi.amount = first_installment.amount
    end

    # Mark installment as paid
    first_installment.update!(
      status: 'paid',
      paid_date: Date.today,
      paid_amount: first_installment.amount
    )
  end

  # 11. Create Notifications
  puts "Creating notifications..."
  Notification.find_or_create_by!(title: 'Bienvenido a MOVICUOTAS', customer: customer) do |n|
    n.body = 'Gracias por confiar en nosotros para tu nuevo dispositivo móvil.'
    n.notification_type = 'general'
    n.sent_at = Time.current
  end
end

# 12. Create Audit Logs (sample)
puts "Creating audit logs..."
AuditLog.find_or_create_by!(action: 'seed_data_created', resource_type: 'Seed', resource_id: 1) do |al|
  al.user = User.system_user
  al.change_details = { seeded_at: Time.current.iso8601 }
  al.ip_address = '127.0.0.1'
  al.user_agent = 'Rails Seeds'
end

  puts "Seeding completed successfully!"
else
  puts "Skipping seeds in #{Rails.env} environment"
end
