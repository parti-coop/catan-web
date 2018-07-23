class CreatePolls < ActiveRecord::Migration[4.2]
  def change
    create_table :polls do |t|
      t.string :title, null: false
      t.timestamps null: false
    end
  end
end
