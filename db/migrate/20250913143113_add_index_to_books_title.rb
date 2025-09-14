class AddIndexToBooksTitle < ActiveRecord::Migration[8.0]
  def change
    add_index :books, :title
  end
end
