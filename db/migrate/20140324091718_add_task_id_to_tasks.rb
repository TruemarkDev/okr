class AddTaskIdToTasks < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks, :task_id, :integer
  end
end
