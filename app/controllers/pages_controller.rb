class PagesController < ApplicationController
  skip_before_action :authenticate, only: [ :home ]

  def home
    # Root page with identity search
  end
end
