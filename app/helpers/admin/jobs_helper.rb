# frozen_string_literal: true

module Admin
  module JobsHelper
    # Mapeo de nombres de jobs a español para mostrar en el UI
    JOB_CLASS_NAMES_ES = {
      "MarkInstallmentsOverdueJob" => "Marcar Cuotas Vencidas",
      "PaymentReminderNotificationJob" => "Recordatorios de Pago",
      "OverduePaymentNotificationJob" => "Notificaciones de Mora",
      "AutoBlockDeviceJob" => "Auto-Bloquear Dispositivos",
      "SendPushNotificationJob" => "Enviar Push Notification",
      "CheckPaymentConfirmationsJob" => "Verificar Confirmaciones de Pago",
      "CleanupOldNotificationsJob" => "Limpiar Notificaciones Antiguas"
    }.freeze

    def job_class_name_es(class_name)
      JOB_CLASS_NAMES_ES[class_name] || class_name
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
