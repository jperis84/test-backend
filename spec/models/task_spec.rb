require 'rails_helper'

RSpec.describe Task, type: :model do
  let(:task) { Task.new }

  describe 'validations' do
    context 'for a new instance without data' do
      it 'validates presence of title, begin_at and end_at' do
        task.save

        expect(task.errors.messages).to eq(
          {
            title: ["can't be blank"],
            begin_at: ["can't be blank"],
            end_at: ["can't be blank"]
          }
        )
      end
    end

    context 'with title, begin_at and end_at present' do
      before do
        task.title = 'Yoga'
        task.begin_at = Time.new(2019, 5, 24, 10, 15)
        task.end_at = Time.new(2019, 5, 24, 12, 15)
      end

      context 'for another task that overlaps this range of time' do
        context 'for same range' do
          before do
            overlap_task = Task.new
            overlap_task.title = 'Overlap Yoga same range'
            overlap_task.begin_at = Time.new(2019, 5, 24, 10, 15)
            overlap_task.end_at = Time.new(2019, 5, 24, 12, 15)
            overlap_task.save
          end

          it 'returns overlap error' do
            task.save

            expect(task.errors.messages).to eq({ end_at: ['Solape de fechas'] })
          end
        end

        context 'for different range but overlap' do
          before do
            overlap_task = Task.new
            overlap_task.title = 'Overlap Yoga'
            overlap_task.begin_at = Time.new(2019, 5, 24, 12, 14)
            overlap_task.end_at = Time.new(2019, 5, 24, 13, 14)
            overlap_task.save
          end

          it 'returns overlap error' do
            task.save

            expect(task.errors.messages).to eq({ end_at: ['Solape de fechas'] })
          end
        end
      end

      context 'without other task that overlaps this date range' do
        context 'and with begin_at before than end_at' do
          it 'saves the record without errors' do
            expect(task.save).to be true
          end
        end

        context 'and with begin_at after than end_at' do
          before do
            task.end_at = Time.new(2019, 5, 24, 10, 15)
            task.begin_at = Time.new(2019, 5, 24, 12, 15)
          end

          it 'returns invalid date range error' do
            task.save

            expect(task.errors.messages).to eq(
              { end_at: ['Fecha de fin debe ser posterior a fecha de inicio'] }
            )
          end
        end
      end

      context 'and with email present' do
        context 'and valid' do
          before do
            task.email = "jorgeperis@gmail.com"
          end

          it 'saves the record without errors' do
            expect(task.save).to be true
          end
        end

        context 'and not valid' do
          before do
            task.email = 'pepito@@gmail.com'
          end

          it 'returns invalid email error' do
            task.save

            expect(task.errors.messages).to eq({ email: ['is invalid']})
          end
        end
      end
    end
  end

  describe 'callbacks' do
    context 'after_create' do
      before do
        task.title = 'Pilates'
        task.begin_at = Time.new(2019, 5, 23)
        task.end_at = Time.new(2019, 5, 24)
      end

      context 'with email present' do
        before do
          task.email = "jorgeperis@gmail.com"
        end

        context 'and begin_at before now' do
          before do
            Timecop.freeze(Time.new(2019, 5, 24))
          end

          it 'not enqueues job to send email' do
            expect(SendEmailJob)
              .to receive(:set)
              .with(wait_until: Time.new(2019, 5, 23))
              .never

            task.save!
          end

          after do
            Timecop.return
          end
        end

        context 'and begin_at after now' do
          before do
            Timecop.freeze(Time.new(2019, 5, 22))

            @job = SendEmailJob.set(wait_until: Time.new(2019, 5, 23))

            allow(SendEmailJob)
              .to receive(:set)
              .with(wait_until: Time.new(2019, 5, 23))
              .and_return(@job)
          end

          it 'enqueues job to send email' do
            expect(@job)
              .to receive(:perform_later)
              .with(anything, Time.new(2019, 5, 22).to_s)
              .once

            task.save!
          end

          after do
            Timecop.return
          end
        end
      end

      context 'without email' do
        it 'not enqueues job to send email' do
          expect(SendEmailJob)
            .to receive(:set)
            .with(wait_until: Time.new(2019, 5, 23))
            .never

          task.save!
        end
      end
    end
  end
end
