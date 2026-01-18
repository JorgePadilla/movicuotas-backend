# frozen_string_literal: true

class Admin::BreadcrumbComponent < ViewComponent::Base
  Item = Struct.new(:name, :path, keyword_init: true)

  # @param items [Array<Hash>] Array of breadcrumb items with :name and optional :path
  # @example
  #   render Admin::BreadcrumbComponent.new(items: [
  #     { name: "Clientes", path: admin_customers_path },
  #     { name: "Juan Pérez" }  # Current page (no path = not a link)
  #   ])
  def initialize(items:)
    @items = items.map { |item| Item.new(**item) }
  end

  attr_reader :items
end
