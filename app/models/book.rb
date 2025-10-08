class Book < ApplicationRecord
  has_many :book_authors, dependent: :destroy
  has_many :authors, through: :book_authors

  has_many :lendings
  has_many :users, through: :lendings
  before_validation :strip_isbn_hyphens

  validates :title, presence: true
  validates :isbn, presence: true, uniqueness: true
  validate :must_have_authors

  attr_accessor :author_names_string

  def can_be_destroyed?
    lendings.unreturned.empty?
  end

  def assign_authors_from_string(names_string)
    self.author_names_string = names_string
    return if names_string.blank?

    names = names_string.split(",").map(&:strip).reject(&:blank?).uniq
    return if names.empty?

    transaction do
      authors = names.map { |name| Author.find_or_create_by!(name: name) }
      self.authors = authors
    end
  end

  scope :search, ->(query) {
    return all.preload(:authors) if query.blank?

    joins(:authors)
      .where("books.title LIKE :q OR books.isbn LIKE :q OR authors.name LIKE :q", q: "%#{query}%")
      .distinct
      .preload(:authors)
  }

  # ビジネスルール: 貸出中の本は削除できない
  before_destroy :ensure_not_lent_out

  private

  def must_have_authors
    if author_names_string.present?
      names = author_names_string.split(",").map(&:strip).reject(&:blank?)
      errors.add(:authors, "を入力してください") if names.empty?
    elsif authors.empty? && persisted?
      errors.add(:authors, "を入力してください")
    end
  end

  def strip_isbn_hyphens
    self.isbn = isbn.delete("-") if isbn.present?
  end

  def ensure_not_lent_out
    unless can_be_destroyed?
      errors.add(:base, "貸出中の本は削除できません")
      throw(:abort)
    end
  end
end
