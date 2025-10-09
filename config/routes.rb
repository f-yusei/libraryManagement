Rails.application.routes.draw do
  get "/signup", to: "users#new"
  resources :users
  resource :session
  resources :books
  resources :lendings, only: %i[create destroy index]
  resources :passwords, param: :token
  get "up" => "rails/health#show", as: :rails_health_check
  root "books#index"
end
