class CustomerSerializer
  def initialize(customer)
    @customer = customer
  end

  def as_json(*args)
    {
      id: @customer.id,
      identification_number: @customer.identification_number,
      full_name: @customer.full_name,
      email: @customer.email,
      phone: @customer.phone,
      date_of_birth: @customer.date_of_birth,
      gender: @customer.gender,
      address: @customer.address,
      city: @customer.city,
      status: @customer.status
    }
  end
end
