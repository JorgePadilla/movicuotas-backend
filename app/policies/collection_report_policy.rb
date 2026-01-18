# frozen_string_literal: true

class CollectionReportPolicy < ApplicationPolicy
  def index?
    admin? || supervisor?
  end
end
