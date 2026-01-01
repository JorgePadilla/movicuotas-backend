# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encounter a deadlock
  retry_on ActiveRecord::Deadlocked, wait: :polynomially_longer, jitter: true

  # Most jobs are safe to ignore if the underlying records are deleted
  discard_on ActiveJob::DeserializationError

  # Default retry strategy: up to 5 attempts with exponential backoff
  retry_on StandardError, wait: :polynomially_longer, attempts: 5 do |job, exception|
    Rails.logger.error("[#{job.class.name}] Job failed with error: #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n"))
  end

  # Configure queue-based job priorities
  # Priority levels: critical (0), high (1), default (5), low (10)
  def self.set_priority(level = :default)
    priority_map = {
      critical: 0,
      high: 1,
      default: 5,
      low: 10
    }
    set(priority: priority_map[level])
  end

  private

  # Helper method to log job execution with context
  def log_execution(message, level = :info, context = {})
    extra = context.any? ? " | #{context.inspect}" : ""
    Rails.logger.send(level, "[#{self.class.name} #{job_id}] #{message}#{extra}")
  end

  # Helper method to track job metrics
  def track_metric(metric_name, value = 1)
    # TODO: Integrate with monitoring service (e.g., New Relic, Datadog)
    # Example: MetricsTracker.increment(metric_name, value)
    log_execution("Metric tracked: #{metric_name} = #{value}", :debug)
  end

  # Helper method to send error notifications
  def notify_error(exception, context = {})
    # TODO: Integrate with error tracking service (e.g., Sentry, Rollbar)
    # Example: ErrorNotifier.notify(exception, context: context.merge(job_class: self.class.name))
    log_execution("Error notification: #{exception.message}", :error, context)
  end

  # Helper to check if job is being retried
  def retry_attempt?
    executions > 1
  end

  # Helper to get current execution count
  def current_attempt
    executions
  end
end
