# frozen_string_literal: true

class DashboardPolicy < ApplicationPolicy
  def index?
    # Each namespace will have its own dashboard policy
    # This base policy denies by default
    false
  end

  class Scope < Scope
    def resolve
      scope.none
    end
  end
end