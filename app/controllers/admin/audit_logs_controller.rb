# frozen_string_literal: true

module Admin
  class AuditLogsController < ApplicationController
    def index
      authorize :audit_log, :index?

      @audit_logs = policy_scope(AuditLog).includes(:user).order(created_at: :desc)

      # Filter by user
      if params[:user_id].present?
        @audit_logs = @audit_logs.where(user_id: params[:user_id])
      end

      # Filter by action
      if params[:action_type].present?
        @audit_logs = @audit_logs.where(action: params[:action_type])
      end

      # Filter by resource type
      if params[:resource_type].present?
        @audit_logs = @audit_logs.where(resource_type: params[:resource_type])
      end

      # Filter by date range
      if params[:date_from].present?
        @audit_logs = @audit_logs.where("created_at >= ?", Date.parse(params[:date_from]).beginning_of_day)
      end
      if params[:date_to].present?
        @audit_logs = @audit_logs.where("created_at <= ?", Date.parse(params[:date_to]).end_of_day)
      end

      # Get unique values for filters
      @users = User.where(id: AuditLog.distinct.pluck(:user_id)).order(:full_name)
      @action_types = AuditLog.distinct.pluck(:action).sort
      @resource_types = AuditLog.distinct.pluck(:resource_type).sort

      # Paginate
      @audit_logs = @audit_logs.page(params[:page]).per(50)
    end

    def show
      @audit_log = AuditLog.find(params[:id])
      authorize :audit_log, :show?
    end
  end
end
