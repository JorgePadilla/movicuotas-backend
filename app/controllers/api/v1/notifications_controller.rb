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
    end
  end
end
