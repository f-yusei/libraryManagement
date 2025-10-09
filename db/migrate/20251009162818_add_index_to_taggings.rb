class AddIndexToTaggings < ActiveRecord::Migration[8.0]
  def change
    add_index :taggings, [ :tag_id, :book_id ], unique: true
  end
end
