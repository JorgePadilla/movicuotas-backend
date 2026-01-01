class LoanSerializer
  def initialize(loan)
    @loan = loan
  end

  def as_json(*args)
    {
      id: @loan.id,
      contract_number: @loan.contract_number,
      customer_id: @loan.customer_id,
      status: @loan.status,
      total_amount: @loan.total_amount,
      approved_amount: @loan.approved_amount,
      down_payment_percentage: @loan.down_payment_percentage,
      down_payment_amount: @loan.down_payment_amount,
      financed_amount: @loan.financed_amount,
      interest_rate: @loan.interest_rate,
      number_of_installments: @loan.number_of_installments,
      start_date: @loan.start_date,
      end_date: @loan.end_date,
      branch_number: @loan.branch_number,
      device: @loan.device ? DeviceSerializer.new(@loan.device).as_json : nil
    }
  end
end
