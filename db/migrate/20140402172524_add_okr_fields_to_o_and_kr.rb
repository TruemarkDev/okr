class AddOkrFieldsToOAndKr < ActiveRecord::Migration[4.2]
  def change
    add_column :objectives, :okr_id, :integer
  end
end
