# frozen_string_literal: true

require "ostruct"

module Admin
  class JobsController < ApplicationController
    skip_after_action :verify_policy_scoped, only: :index
    skip_after_action :verify_authorized, only: [ :index, :show, :retry, :trigger, :cancel ]
    before_action :require_login
    before_action :authorize_admin
    before_action :set_job, only: [ :show, :retry, :cancel ]

    def index
      # Load job metrics
      load_job_metrics

      # Load available queues and job classes
      @queues = fetch_available_queues
      @job_classes = fetch_available_job_classes

      # Load jobs list with filters
      @jobs = fetch_jobs_list
    end

    def show
      @failed_execution = SolidQueue::FailedExecution.find_by(job_id: @job.id)
      @job_status = determine_job_status(@job)
    end

    def retry
      failed_execution = SolidQueue::FailedExecution.find_by(job_id: @job.id)

      if failed_execution
        failed_execution.retry
        redirect_to admin_jobs_path, notice: "Job reiniciado exitosamente."
      else
        redirect_to admin_jobs_path, alert: "No se pudo reiniciar el job."
      end
    end

    def cancel
      if can_cancel_job?(@job)
        cancel_job!(@job)
        redirect_to admin_jobs_path, notice: "Job cancelado exitosamente."
      else
        status = determine_job_status(@job)
        redirect_to admin_jobs_path, alert: "No se puede cancelar un job en estado: #{status}"
      end
    end

    def trigger
      job_class_name = params[:job_class]

      # Validate job class against whitelist
      unless valid_job_class?(job_class_name)
        redirect_to admin_jobs_path, alert: "Job no válido."
        return
      end

      # Get the validated class name from the whitelist to avoid unsafe reflection
      # brakeman:disable:UnsafeReflection - job_class_name is validated against ALLOWED_JOB_CLASSES whitelist
      validated_class_name = ALLOWED_JOB_CLASSES.find { |c| c == job_class_name }
      job_class = validated_class_name.constantize
      job_class.perform_later

      redirect_to admin_jobs_path, notice: "#{validated_class_name} ha sido encolado exitosamente."
    rescue NameError => e
      Rails.logger.error "Error triggering job - Class not found: #{e.message}"
      redirect_to admin_jobs_path, alert: "Error: Job class no encontrado. Por favor reinicia el servidor."
    rescue StandardError => e
      Rails.logger.error "Error triggering job: #{e.class} - #{e.message}"
      redirect_to admin_jobs_path, alert: "Error al encolar el job: #{e.message}"
    end

    private

    def require_login
      redirect_to login_path, alert: "Debes iniciar sesión" unless current_user
    end

    def authorize_admin
      redirect_to root_path, alert: "Acceso denegado" unless current_user&.admin?
    end

    def set_job
      @job = SolidQueue::Job.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_jobs_path, alert: "Job no encontrado."
    end

    ALLOWED_JOB_CLASSES = [
      "MarkInstallmentsOverdueJob",
      "PaymentReminderNotificationJob",
      "OverduePaymentNotificationJob",
      "SendTestNotificationJob"
    ].freeze

    # Jobs internos de Rails/SolidQueue que no queremos mostrar en el dashboard
    INTERNAL_JOB_PREFIXES = [
      "ActiveStorage::",
      "ActionMailbox::",
      "ActionMailer::",
      "ActiveJob::",
      "SolidQueue::"
    ].freeze

    def valid_job_class?(job_class)
      ALLOWED_JOB_CLASSES.include?(job_class)
    end

    def internal_job?(class_name)
      INTERNAL_JOB_PREFIXES.any? { |prefix| class_name.to_s.start_with?(prefix) }
    end

    def load_job_metrics
      today = Time.current.beginning_of_day

      # Base query excluding internal jobs
      base_jobs = exclude_internal_jobs(SolidQueue::Job)

      @total_jobs_today = base_jobs.where("created_at >= ?", today).count
      @completed_jobs = base_jobs.where.not(finished_at: nil)
        .where("finished_at >= ?", today).count

      # For executions, we need to filter by job_id
      internal_job_ids = SolidQueue::Job.where(internal_job_condition).pluck(:id)
      @failed_jobs = SolidQueue::FailedExecution.where.not(job_id: internal_job_ids).count
      @running_jobs = SolidQueue::ClaimedExecution.where.not(job_id: internal_job_ids).count
      @pending_jobs = SolidQueue::ReadyExecution.where.not(job_id: internal_job_ids).count
      @scheduled_jobs = SolidQueue::ScheduledExecution.where.not(job_id: internal_job_ids).count
    end

    def fetch_available_queues
      exclude_internal_jobs(SolidQueue::Job).distinct.pluck(:queue_name).compact.sort
    end

    def fetch_available_job_classes
      exclude_internal_jobs(SolidQueue::Job).distinct.pluck(:class_name).compact.sort
    end

    def exclude_internal_jobs(scope)
      INTERNAL_JOB_PREFIXES.each do |prefix|
        scope = scope.where.not("class_name LIKE ?", "#{prefix}%")
      end
      scope
    end

    def internal_job_condition
      INTERNAL_JOB_PREFIXES.map { |prefix| "class_name LIKE '#{prefix}%'" }.join(" OR ")
    end

    def fetch_jobs_list
      jobs = SolidQueue::Job.order(created_at: :desc)

      # Exclude internal Rails jobs (ActiveStorage, ActionMailer, etc.)
      INTERNAL_JOB_PREFIXES.each do |prefix|
        jobs = jobs.where.not("class_name LIKE ?", "#{prefix}%")
      end

      # Apply status filter
      jobs = apply_status_filter(jobs) if params[:status].present? && params[:status] != "all"

      # Apply queue filter
      jobs = jobs.where(queue_name: params[:queue]) if params[:queue].present?

      # Apply job class filter
      jobs = jobs.where(class_name: params[:job_class]) if params[:job_class].present?

      # Apply search
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        jobs = jobs.where("class_name ILIKE ? OR id::text LIKE ?", search_term, search_term)
      end

      # Manual pagination (Solid Queue models don't work well with Kaminari)
      total_count = jobs.count
      page = (params[:page] || 1).to_i
      per_page = 25
      offset = (page - 1) * per_page

      jobs_page = jobs.limit(per_page).offset(offset).to_a

      # Create a simple paginated collection
      OpenStruct.new(
        records: jobs_page,
        total_count: total_count,
        current_page: page,
        total_pages: (total_count.to_f / per_page).ceil,
        per_page: per_page,
        offset_value: offset,
        size: jobs_page.size,
        any?: jobs_page.any?
      )
    end

    def apply_status_filter(jobs)
      case params[:status]
      when "pending"
        job_ids = SolidQueue::ReadyExecution.pluck(:job_id)
        jobs.where(id: job_ids)
      when "running"
        job_ids = SolidQueue::ClaimedExecution.pluck(:job_id)
        jobs.where(id: job_ids)
      when "failed"
        job_ids = SolidQueue::FailedExecution.pluck(:job_id)
        jobs.where(id: job_ids)
      when "scheduled"
        job_ids = SolidQueue::ScheduledExecution.pluck(:job_id)
        jobs.where(id: job_ids)
      when "completed"
        jobs.where.not(finished_at: nil)
      else
        jobs
      end
    end

    def determine_job_status(job)
      return "failed" if SolidQueue::FailedExecution.exists?(job_id: job.id)
      return "running" if SolidQueue::ClaimedExecution.exists?(job_id: job.id)
      return "scheduled" if SolidQueue::ScheduledExecution.exists?(job_id: job.id)
      return "pending" if SolidQueue::ReadyExecution.exists?(job_id: job.id)
      return "completed" if job.finished_at.present?

      "unknown"
    end

    def can_cancel_job?(job)
      # Can only cancel pending or scheduled jobs
      SolidQueue::ReadyExecution.exists?(job_id: job.id) ||
        SolidQueue::ScheduledExecution.exists?(job_id: job.id)
    end

    def cancel_job!(job)
      # Delete from pending execution queue
      SolidQueue::ReadyExecution.where(job_id: job.id).destroy_all

      # Delete from scheduled execution queue
      SolidQueue::ScheduledExecution.where(job_id: job.id).destroy_all

      # Mark job as cancelled by updating finished_at
      job.update!(finished_at: Time.current)
    end
  end
end
