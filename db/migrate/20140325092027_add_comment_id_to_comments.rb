class AddCommentIdToComments < ActiveRecord::Migration[4.2]
  def change
    add_column :comments, :comment_id, :integer
  end
end
