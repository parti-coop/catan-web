class CreateLinks < ActiveRecord::Migration
  def change
    create_table :links do |t|
      t.string :title
      t.text :body
      t.text :metadata
      t.string :image
      t.string :page_type
      t.string :url, length: 1000
      t.string :crawling_status, default: :not_yet, null: false
      t.datetime :crawled_at
      t.timestamps null: false
    end

    add_index :links, :url, unique: true
  end
end
