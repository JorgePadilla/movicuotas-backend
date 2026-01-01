# frozen_string_literal: true

module Admin
  class JobsController < ApplicationController
    skip_after_action :verify_policy_scoped, only: :index
    skip_after_action :verify_authorized, only: [:index, :show, :retry]
    before_action :require_login
    before_action :authorize_admin
    before_action :set_job, only: [:show, :retry]

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

    def load_job_metrics
      today = Time.current.beginning_of_day

      @total_jobs_today = SolidQueue::Job.where("created_at >= ?", today).count
      @completed_jobs = SolidQueue::Job.where.not(finished_at: nil)
        .where("finished_at >= ?", today).count
      @failed_jobs = SolidQueue::FailedExecution.count
      @running_jobs = SolidQueue::ClaimedExecution.count
      @pending_jobs = SolidQueue::ReadyExecution.count
      @scheduled_jobs = SolidQueue::ScheduledExecution.count
    end

    def fetch_available_queues
      SolidQueue::Job.distinct.pluck(:queue_name).sort
    end

    def fetch_available_job_classes
      SolidQueue::Job.distinct.pluck(:class_name).sort
    end

    def fetch_jobs_list
      jobs = SolidQueue::Job.order(created_at: :desc)

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

      # Paginate
      jobs.page(params[:page]).per(25)
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
  end
end
