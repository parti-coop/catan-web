class AddAdmitMessageToMembers < ActiveRecord::Migration[4.2]
  def change
    add_column :members, :admit_message, :text, limit: 16.megabytes - 1
  end
end
