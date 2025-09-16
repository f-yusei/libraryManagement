class Book < ApplicationRecord
  attr_accessor :author_names
  has_many :book_authors, dependent: :destroy
  has_many :authors, through: :book_authors

  has_many :lendings
  has_many :users, through: :lendings
  before_validation :strip_isbn_hyphens

  validates :title, presence: true
  validates :isbn, presence: true, uniqueness: true
  validates :author_names, presence: true

  scope :search, ->(query) {
    return all.preload(:authors) if query.blank?

    joins(:authors)
      .where("books.title LIKE :q OR books.isbn LIKE :q OR authors.name LIKE :q", q: "%#{query}%")
      .distinct
      .preload(:authors)
  }

  private

  def strip_isbn_hyphens
    self.isbn = isbn.delete("-") if isbn.present?
  end
end
