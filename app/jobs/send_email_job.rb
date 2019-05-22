class SendEmailJob < ApplicationJob
  queue_as :default

  def perform(task_id, task_updated_at)
    task = Task.find_by(id: task_id)

    return unless task.present?
    return unless task.email.present?
    return if task.updated_at.to_json != task_updated_at

    TaskMailer.send_notification_mail(
      task.email,
      task.title,
      task.begin_at,
      task.end_at
    ).deliver_now
  end
end
