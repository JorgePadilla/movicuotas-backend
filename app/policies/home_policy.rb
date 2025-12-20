# frozen_string_literal: true

class HomePolicy < ApplicationPolicy
  def index?
    true  # Everyone can access root
  end

  class Scope < Scope
    def resolve
      scope.none
    end
  end
end
