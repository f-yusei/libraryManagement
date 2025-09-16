class CreateLendings < ActiveRecord::Migration[8.0]
  def change
    create_table :lendings do |t|
      t.references :book, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :checked_out_at, null: false
      t.datetime :returned_at
      t.datetime :due_date, null: false

      t.timestamps
    end
  end
end
