class Book < ApplicationRecord
  has_many :book_authors, dependent: :destroy
  has_many :authors, through: :book_authors

  has_many :lendings
  has_many :users, through: :lendings
  before_validation :strip_isbn_hyphens

  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings

  validates :title, presence: true
  validates :isbn, presence: true, uniqueness: true

  scope :search, ->(query) {
    return all.preload(:authors) if query.blank?

    joins(:authors)
      .where("books.title LIKE :q OR books.isbn LIKE :q OR authors.name LIKE :q", q: "%#{query}%")
      .distinct
      .preload(:authors)
  }

  # ビジネスルール: 貸出中の本は削除できない
  before_destroy :ensure_not_lent_out

  def can_be_destroyed?
    lendings.unreturned.empty?
  end

  private

  def ensure_not_lent_out
    unless can_be_destroyed?
      errors.add(:base, "貸出中の本は削除できません")
      throw(:abort)
    end
  end

  def strip_isbn_hyphens
    self.isbn = isbn.delete("-") if isbn.present?
  end
end
