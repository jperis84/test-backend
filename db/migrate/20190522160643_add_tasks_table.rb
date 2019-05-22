class AddTasksTable < ActiveRecord::Migration[5.2]
  def up
    create_table :tasks do |t|
      t.string :title
      t.datetime :begin_at
      t.datetime :end_at
      t.string :email

      t.timestamps
    end
  end

  def down
    drop_table :tasks
  end
end
