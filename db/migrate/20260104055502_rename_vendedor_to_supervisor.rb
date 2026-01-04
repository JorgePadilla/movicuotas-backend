# frozen_string_literal: true

class RenameVendedorToSupervisor < ActiveRecord::Migration[8.1]
  def up
    # Update all users with role 'vendedor' to 'supervisor'
    execute "UPDATE users SET role = 'supervisor' WHERE role = 'vendedor'"
  end

  def down
    # Revert: Update all users with role 'supervisor' back to 'vendedor'
    execute "UPDATE users SET role = 'vendedor' WHERE role = 'supervisor'"
  end
end
