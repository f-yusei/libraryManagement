# db/seeds.rb

# ---- ユーザー ----
users = User.create!([
  { name: "Alice", email_address: "test1@example.com", password: "password" },
  { name: "Bob",   email_address: "test2@example.com",   password: "password" },
  { name: "Carol", email_address: "test3@example.com", password: "password" }
])

# ---- 著者 ----
authors = Author.create!([
  { name: "Yukihiro Matsumoto" },
  { name: "David Heinemeier Hansson" },
  { name: "Martin Fowler" }
])

# ---- 書籍 ----
books = Book.create!([
  { title: "Programming Ruby", isbn: "9781234567890", published_year: Date.new(2008, 1, 1),
    publisher: "O'Reilly Japan", stock_count: 3 },
  { title: "Agile Web Development with Rails", isbn: "9781234567891", published_year: Date.new(2010, 6, 1),
    publisher: "Pragmatic Bookshelf", stock_count: 2 },
  { title: "Refactoring", isbn: "9781234567892", published_year: Date.new(2018, 11, 1),
    publisher: "Addison-Wesley", stock_count: 1 }
])

# ---- 書籍と著者の関連付け ----
BookAuthor.create!([
  { book: books[0], author: authors[0] }, # Programming Ruby ← Matz
  { book: books[1], author: authors[1] }, # Agile Web Dev ← DHH
  { book: books[2], author: authors[2] }, # Refactoring ← Fowler
  # 複数著者パターン
  { book: books[1], author: authors[2] }  # Agile Web Dev ← Fowler も
])
