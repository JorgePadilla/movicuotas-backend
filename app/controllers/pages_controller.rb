class PagesController < ApplicationController
  skip_before_action :authenticate, only: [ :home ]
  skip_after_action :verify_authorized, only: [ :home ]
  skip_after_action :verify_policy_scoped, only: [ :home ]

  def home
    # Root page with identity search
    # Redirect to customer search if user is already logged in
    if current_user
      redirect_to root_path
      return
    end

    authorize :page
  end
end
