class TasksController < ApplicationController
  def index
    @past_tasks = Task.past
    @actual_tasks = Task.actual
    @future_tasks = Task.future
  end

  def show
    @task = Task.find(params[:id])
  end

  def new
    @task = Task.new
  end

  def edit
    @task = Task.find(params[:id])
  end

  def create
    @task = Task.new(task_params)

    if @task.save
      redirect_to tasks_path
    else
      render :new
    end
  end

  def update
    @task = Task.find(params[:id])

    @task.assign_attributes(task_params)

    if @task.save
      @task.schedule_job_to_send_email

      redirect_to tasks_path
    else
      render :edit
    end
  end

  def destroy
    task = Task.find(params[:id])

    task.destroy!

    redirect_to tasks_path
  end

  private

  def task_params
    params.require(:task).permit(
      :title,
      :begin_at,
      :end_at,
      :email
    )
  end
end
