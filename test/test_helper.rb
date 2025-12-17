ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

# Define stub controllers for authentication tests
# These are needed because routes exist but controllers are in other branches
module Admin
  class DashboardController < ApplicationController
    def index
      head :ok
    end
  end
end

module Vendor
  class CustomerSearchController < ApplicationController
    def index
      head :ok
    end
  end
end

module Cobrador
  class DashboardController < ApplicationController
    def index
      head :ok
    end
  end
end
