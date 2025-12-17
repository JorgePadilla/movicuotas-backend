class PagesController < ApplicationController
  skip_before_action :authenticate, only: [ :home ]
  skip_after_action :verify_authorized, only: [ :home ]
  skip_after_action :verify_policy_scoped, only: [ :home ]

  def home
    # Root page with identity search
  end
end
