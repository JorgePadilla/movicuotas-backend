# Policy for PagesController
class PagePolicy < ApplicationPolicy
  # Allow anyone to access home page (public)
  def home?
    true
  end
end