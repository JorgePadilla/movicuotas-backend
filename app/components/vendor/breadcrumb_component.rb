# frozen_string_literal: true

class Vendor::BreadcrumbComponent < ViewComponent::Base
  Item = Struct.new(:name, :path, keyword_init: true)

  # @param items [Array<Hash>] Array of breadcrumb items with :name and optional :path
  # @example
  #   render Vendor::BreadcrumbComponent.new(items: [
  #     { name: "Préstamos", path: vendor_loans_path },
  #     { name: "Préstamo #123" }
  #   ])
  def initialize(items:)
    @items = items.map { |item| Item.new(**item) }
  end

  attr_reader :items
end
