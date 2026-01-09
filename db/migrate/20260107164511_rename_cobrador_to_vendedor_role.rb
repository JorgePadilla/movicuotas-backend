# frozen_string_literal: true

# Migration to update user roles to new naming convention:
#
# OLD ROLES -> NEW ROLES
# - supervisor (sales, branch-limited) -> vendedor
# - cobrador (collections, blocking) -> supervisor
#
# NEW ROLE DEFINITIONS:
# - admin: Full system access
# - supervisor: Payment verification, device blocking (NOT branch-limited)
# - vendedor: Customer registration, loan creation (branch-limited)
class RenameCobradorToVendedorRole < ActiveRecord::Migration[8.0]
  def up
    # Use a single atomic UPDATE with CASE to swap roles
    # This ensures no intermediate state issues
    execute <<-SQL.squish
      UPDATE users SET role = CASE
        WHEN role = 'cobrador' THEN 'supervisor'
        WHEN role = 'supervisor' THEN 'vendedor'
        ELSE role
      END
    SQL
  end

  def down
    # Reverse the swap
    execute <<-SQL.squish
      UPDATE users SET role = CASE
        WHEN role = 'supervisor' THEN 'cobrador'
        WHEN role = 'vendedor' THEN 'supervisor'
        ELSE role
      END
    SQL
  end
end
