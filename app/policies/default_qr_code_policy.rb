# frozen_string_literal: true

class DefaultQrCodePolicy < ApplicationPolicy
  # Default QR code policies
  # - Only Admin can manage default QR codes
  # - All users can view the default QR code

  def index?
    admin?
  end

  def edit?
    admin?
  end

  def update?
    admin?
  end

  def download?
    admin?
  end
end
