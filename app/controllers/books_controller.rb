class BooksController < ApplicationController
  allow_unauthenticated_access only: %i[index show]
  def index
    @books = Book.search(params[:q])
  end

  def show
    @book = Book.find(params[:id])
  end

  def edit
    @book = Book.find(params[:id])
  end
end
