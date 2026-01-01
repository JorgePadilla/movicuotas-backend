# frozen_string_literal: true

module Vendor
  class ReportPolicy < ApplicationPolicy
    def index?
      user&.vendedor? || user&.admin?
    end
  end
end
