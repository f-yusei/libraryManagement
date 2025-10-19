class RenameBooksPublishedYearToPublishedDate < ActiveRecord::Migration[8.0]
  def change
    rename_column :books, :published_year, :published_date
  end
end
