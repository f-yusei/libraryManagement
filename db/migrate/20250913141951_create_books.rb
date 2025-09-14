class CreateBooks < ActiveRecord::Migration[8.0]
  def change
    create_table :books do |t|
      t.string :title, null:false
      t.string :isbn, null:false
      t.date :published_year
      t.string :publisher
      t.integer :stock_count, default: 0, null:false

      t.timestamps
    end
    add_index :books, :isbn, unique: true
  end
end
