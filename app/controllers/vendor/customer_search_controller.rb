# frozen_string_literal: true

module Vendor
  class CustomerSearchController < ApplicationController
    skip_after_action :verify_policy_scoped, only: :index

    def index
      authorize :customer_search
      # Placeholder for customer search main screen
    end
  end
end