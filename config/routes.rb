Rails.application.routes.draw do
  resources :markets
  resources :companies
  resources :issuances
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
