class AddCompletionDateToTasks < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks, :completed_on, :datetime
  end
end
