# frozen_string_literal: true

module Vendor
  class ReportsController < ApplicationController
    def index
      authorize nil, policy_class: Vendor::ReportPolicy
      # Reports index - currently a placeholder for future development
    end
  end
end
