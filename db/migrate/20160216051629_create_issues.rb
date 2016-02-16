class CreateIssues < ActiveRecord::Migration
  def change
    create_table :issues do |t|
      t.string :title, null: false, index: true
      t.timestamps null: false
    end
  end
end
