class AddImageUrlToBook < ActiveRecord::Migration[8.0]
  def change
    add_column :books, :image_url, :string
  end
end
