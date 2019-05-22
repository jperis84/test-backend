class TaskMailer < ApplicationMailer
  def send_notification_mail(email, title, begin_at, end_at)
    @title = title
    @begin_at = begin_at
    @end_at = end_at

    mail(to: email, subject: 'Acaba iniciar una actividad')
  end
end
