class AddApprovalToOkrs < ActiveRecord::Migration[4.2]
  def change
    add_column :okrs, :approved, :boolean,:default=>false
  end
end
