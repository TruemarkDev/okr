class CreateTaskKeyResults < ActiveRecord::Migration[4.2]
  def change
    create_table :task_key_results do |t|
      t.integer :task_id
      t.integer :key_result_id

      t.timestamps
    end
  end
end
