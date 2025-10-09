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

  # シンプルなバリデーション：保存時に著者が存在するかチェック
  validate :must_have_authors_on_save

  attr_accessor :author_names_string, :tag_names_string

  def assign_authors(names_string)
    # 著者名文字列を保存（バリデーション用）
    self.author_names_string = names_string

    names = parse_names(names_string)
    if names.empty?
      self.authors = []
    else
      authors = names.map { |name| find_or_create_author(name) }
      self.authors = authors
    end
  end

  def assign_tags(names_string)
    # タグ名文字列を保存
    self.tag_names_string = names_string

    # タグはオプショナルなので、空文字列やnilの場合は全てクリア
    if names_string.blank?
      self.tags = []
      return
    end

    names = parse_names(names_string)
    if names.empty?
      self.tags = []
    else
      tags = names.map { |name| find_or_create_tag(name) }
      self.tags = tags
    end
  end

  scope :search, ->(query) {
    return all.preload(:authors, :tags) if query.blank?

    # LEFT JOINを使用して、著者やタグがない本も含める
    left_joins(:authors, :tags)
      .where(
        "books.title LIKE :q OR books.isbn LIKE :q OR authors.name LIKE :q OR tags.name LIKE :q",
        q: "%#{query}%"
      )
      .distinct
      .preload(:authors, :tags)
  }

  # ビジネスルール: 貸出中の本は削除できない
  before_destroy :ensure_not_lent_out

  def can_be_destroyed?
    lendings.unreturned.empty?
  end

  private

  def must_have_authors_on_save
    if authors.empty?
      errors.add(:authors, "を入力してください")
    end
  end

  def parse_names(names_string)
    return [] if names_string.nil?
    names_string.split(",").map(&:strip).reject(&:blank?).uniq
  end

  def find_or_create_author(name)
    Author.find_or_create_by(name: name)
  rescue ActiveRecord::RecordNotUnique
    Author.find_by!(name: name)
  end

  def find_or_create_tag(name)
    Tag.find_or_create_by(name: name)
  rescue ActiveRecord::RecordNotUnique
    Tag.find_by!(name: name)
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
