# frozen_string_literal: true

class Supervisor::BreadcrumbComponent < ViewComponent::Base
  Item = Struct.new(:name, :path, keyword_init: true)

  # @param items [Array<Hash>] Array of breadcrumb items with :name and optional :path
  # @example
  #   render Supervisor::BreadcrumbComponent.new(items: [
  #     { name: "Dispositivos en Mora", path: supervisor_overdue_devices_path },
  #     { name: "Dispositivo #123" }
  #   ])
  def initialize(items:)
    @items = items.map { |item| Item.new(**item) }
  end

  attr_reader :items
end
