# Library Management System - Copilot Instructions

## Architecture Overview

This is a Rails 8 library management system with a book lending workflow. The core domain models form a lending ecosystem:
- **Books** have multiple **Authors** (via `book_authors` join table)
- **Users** can borrow **Books** through **Lendings** with due dates and return tracking
- **Sessions** handle authentication via `ActiveSupport::CurrentAttributes`

## Key Patterns & Conventions

### Authentication & Authorization
- Uses Rails 8's built-in authentication with `has_secure_password`
- **Custom patterns**: `Authentication` and `Authorization` concerns in `app/controllers/concerns/`
- Controllers use `allow_unauthenticated_access only: %i[action]` for public endpoints
- Admin-only actions use `admin_only only: %i[action]` class method
- Current user accessible via `Current.session.user` (not `session[:user_id]`)

### Domain Logic in Models
- **Transaction safety**: `Lending.lend_to(user, book)` handles stock decrements in transactions
- **Custom exceptions**: `Lending::OutOfStockError` for business rule violations
- **Scoped queries**: `Book.search(query)` with preloading, `Lending.unreturned`
- **Instance methods for state changes**: `lending.return!` with validation

### Data Integrity Patterns
- ISBN normalization via `before_validation :strip_isbn_hyphens`
- Email normalization using Rails 8's `normalizes` with lambda
- Foreign key constraints enforced at database level

## Development Workflow

### Local Development
```bash
bin/dev          # Starts Rails server + CSS watching via Procfile.dev
bin/rails test   # Run test suite (uses parallel workers)
```

### Database Operations
- Uses SQLite with Solid Cache/Queue/Cable for Rails 8 features
- Models use `preload(:association)` for N+1 prevention
- Search implemented with raw SQL LIKE queries (not full-text search)

## Controller Patterns

### Error Handling
```ruby
# Pattern for business logic errors
rescue Lending::OutOfStockError
  redirect_to book, flash: { danger: "在庫がありません。" }

# Pattern for validation errors in create actions
rescue ActiveRecord::RecordInvalid => e
  flash.now[:alert] = "登録に失敗しました。 #{e.message}"
  render :new, status: :unprocessable_entity
```

### Flash Messages
- Success: `flash: { success: "message" }`
- Errors: `flash: { danger: "message" }` or `flash.now[:alert]`
- Japanese error messages throughout

### Resource Management
- Book creation handles comma-separated author names: `params[:author_names].split(",")`
- Uses `find_or_create_by!` for author deduplication
- Transaction wraps both book creation and author association

## Testing Conventions

- Fixtures in `test/fixtures/*.yml`
- Helper method: `sign_in_as(user, password: "password", follow: false)`
- Parallel test execution enabled
- Uses Rails' built-in minitest framework

## Configuration Notes

- Modern browser requirement enforced via `allow_browser versions: :modern`
- Admin creation disabled in `config/initializers/ensure_admin.rb` (commented out)
- Japanese locale used for user-facing messages
- Stock management via integer `stock_count` field, not separate inventory model