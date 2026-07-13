class AddDeleteRequestToWorkLogs < ActiveRecord::Migration[4.2]
  def change
    add_column :work_logs, :delete_request, :boolean, :default => 0
  end
end
