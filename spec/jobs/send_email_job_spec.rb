require 'rails_helper'

RSpec.describe SendEmailJob, type: :job do
  include ActiveJob::TestHelper

  let(:job) { described_class.perform_later(id, updated_at) }

  let(:id) { 123 }
  let(:updated_at) { Time.new(2019, 5, 23).to_s }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(id, updated_at)
      .on_queue("default")
  end

  describe 'Send email' do
    let :task do
      task = Task.new
      task.title = 'Pilates'
      task.email = 'jorgeperis@gamil.com'
      task.begin_at = Time.new(2019, 5, 23)
      task.end_at = Time.new(2019, 5, 24)
      task.save

      task
    end

    before do
      allow(TaskMailer).to receive_message_chain(:send_notification_mail, :deliver_now)
    end

    context 'for not present task' do
      it 'not enqueues TaskMailer' do
        expect(TaskMailer).to receive(:send_notification_mail).never

        described_class.new.perform(123, Time.new(2019, 5, 24).to_s)
      end
    end

    context 'for present task' do
      context 'and task without email' do
        before do
          task.email = nil
          task.save
        end

        it 'not enqueues TaskMailer' do
          expect(TaskMailer).to receive(:send_notification_mail).never

          described_class.new.perform(task.id, task.updated_at.to_s)
        end
      end

      context 'and task with email' do
        context 'and updated_at different to task.updated_at' do
          let(:updated_at) { (task.updated_at - 1.second).to_s }

          it 'not enqueues TaskMailer' do
            expect(TaskMailer).to receive(:send_notification_mail).never

            described_class.new.perform(task.id, updated_at)
          end
        end

        context  'and updated_at equal to task.updated_at' do
          let(:updated_at) { task.updated_at.to_s }

          it 'enqueues TaskMailer' do
            expect(TaskMailer)
              .to receive(:send_notification_mail)
              .with(
                'jorgeperis@gamil.com',
                'Pilates',
                Time.new(2019, 5, 23),
                Time.new(2019, 5, 24)
              ).once

            described_class.new.perform(task.id, updated_at)
          end
        end
      end
    end
  end
end
