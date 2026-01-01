class DeviceSerializer
  def initialize(device)
    @device = device
  end

  def as_json(*args)
    {
      id: @device.id,
      imei: @device.imei,
      brand: @device.brand,
      model: @device.model,
      phone_model_id: @device.phone_model_id,
      lock_status: @device.lock_status,
      is_locked: @device.locked?
    }
  end
end
