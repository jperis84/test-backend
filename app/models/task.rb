class Task < ApplicationRecord
  validates :title, :begin_at, :end_at, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true, allow_blank: true

  validates :begin_at, :end_at, uniqueness: true

  validate :uniqueness_range_of_time, on: :create
  validate :end_at_after_start_at?

  scope :overlaps, ->(begin_at, end_at) {
    where("((begin_at <= ?) and (end_at >= ?))", end_at, begin_at)
  }

  scope :past,   -> { where('end_at < ?', Time.now) }
  scope :actual, -> { where('? between begin_at and end_at', Time.now)}
  scope :future, -> { where('begin_at > ?', Time.now) }

  after_create :schedule_job_to_send_email

  def schedule_job_to_send_email
    return unless email.present?

    SendEmailJob.set(wait_until: begin_at.to_json).perform_later(id, updated_at.to_json)
  end

  private

  def uniqueness_range_of_time
    return if self.class.overlaps(begin_at, end_at).empty?

    errors.add(:end_at, 'Solape de fechas')
  end

  def end_at_after_start_at?
    return if end_at > begin_at

    errors.add(:end_at, 'Fecha de fin debe ser posterior a fecha de inicio')
  end
end
