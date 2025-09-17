# Users
alice = User.find_or_create_by!(email_address: "alice@example.com") do |user|
  user.name = "Alice"
  user.password = "password"
  user.password_confirmation = "password"
  user.admin = true
end

bob = User.find_or_create_by!(email_address: "bob@example.com") do |user|
  user.name = "Bob"
  user.password = "password"
  user.password_confirmation = "password"
  user.admin = false
end

carol = User.find_or_create_by!(email_address: "carol@example.com") do |user|
  user.name = "Carol"
  user.password = "password"
  user.password_confirmation = "password"
  user.admin = false
end

# Authors
natsume = Author.find_or_create_by!(name: "夏目漱石")
dazai   = Author.find_or_create_by!(name: "太宰治")

# Books
book1 = Book.find_or_create_by!(isbn: "9781234567890") do |book|
  book.title = "吾輩は猫である"
  book.publisher = "岩波書店"
  book.published_year = Date.new(1905, 1, 1)
  book.stock_count = 3
end
book1.authors << natsume unless book1.authors.include?(natsume)

book2 = Book.find_or_create_by!(isbn: "9789876543210") do |book|
  book.title = "人間失格"
  book.publisher = "新潮社"
  book.published_year = Date.new(1948, 1, 1)
  book.stock_count = 2
end
book2.authors << dazai unless book2.authors.include?(dazai)
