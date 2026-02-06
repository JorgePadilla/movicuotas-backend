class BackfillInstallmentCounters < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL
      UPDATE loans SET
        paid_installments_count = (
          SELECT COUNT(*) FROM installments
          WHERE installments.loan_id = loans.id AND installments.status = 'paid'
        ),
        overdue_installments_count = (
          SELECT COUNT(*) FROM installments
          WHERE installments.loan_id = loans.id AND installments.status = 'overdue'
        ),
        next_due_date = (
          SELECT MIN(due_date) FROM installments
          WHERE installments.loan_id = loans.id AND installments.status = 'pending'
        )
    SQL
  end

  def down
    # No-op: columns will be removed by the previous migration rollback
  end
end
