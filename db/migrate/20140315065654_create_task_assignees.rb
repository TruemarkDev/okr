class CreateTaskAssignees < ActiveRecord::Migration[4.2]
  def change
    create_table :task_assignees do |t|
      t.integer :task_id
      t.integer :user_id

      t.timestamps
    end
  end
end
