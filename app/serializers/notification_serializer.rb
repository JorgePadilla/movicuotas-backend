class NotificationSerializer
  def initialize(notification)
    @notification = notification
  end

  def as_json(*args)
    {
      id: @notification.id,
      title: @notification.title,
      message: @notification.message,
      notification_type: @notification.notification_type,
      is_read: @notification.read?,
      created_at: @notification.created_at,
      data: @notification.data
    }
  end
end
