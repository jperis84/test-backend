class TaskMailerPreview < ActionMailer::Preview
  def send_notification_mail
    TaskMailer.send_notification_mail('jorgeperis@gmail.com', "Pilates", Time.now, 1.hour.from_now)
  end
end
