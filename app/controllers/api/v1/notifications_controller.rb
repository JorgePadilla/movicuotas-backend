module Api
  module V1
    class NotificationsController < BaseController
      def index
        customer = current_customer
        notifications = customer.notifications.order(created_at: :desc)

        page = params[:page] || 1
        per_page = params[:per_page] || 10

        paginated = notifications.page(page).per(per_page)

        render_success({
          notifications: paginated.map { |n| NotificationSerializer.new(n).as_json },
          pagination: {
            current_page: paginated.current_page,
            total_pages: paginated.total_pages,
            total_count: paginated.total_count,
            per_page: per_page
          }
        })
      end

      def mark_read
        notification = current_customer.notifications.find_by(id: params[:id])

        if notification
          notification.mark_as_read!
          render_success({ message: "Notification marked as read" })
        else
          render_error("Notification not found", :not_found)
        end
      end

      def mark_all_read
        current_customer.notifications.unread.update_all(read_at: Time.current)
        render_success({ message: "All notifications marked as read" })
      end
    end
  end
end
