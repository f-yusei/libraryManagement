class Book < ApplicationRecord
  has_many :book_authors, dependent: :destroy
  has_many :authors, through: :book_authors

  has_many :lendings
  has_many :users, through: :lendings
  # TODO:isbnを-なしで保存するようにする
end
