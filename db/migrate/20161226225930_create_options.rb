class CreateOptions < ActiveRecord::Migration
  def change
    create_table :options do |t|
      t.references :survey, null: false, index: true
      t.text :body
      t.integer :feedbacks_counts, default: 0
      t.timestamps null: false
    end
  end
end