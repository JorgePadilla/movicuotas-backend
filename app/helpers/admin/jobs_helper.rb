# frozen_string_literal: true

module Admin
  module JobsHelper
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
