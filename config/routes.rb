Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  resources :treasures, only: [:create, :destroy]
  resources :guesses, only: [:create]

  get '/treasures/:id/winners', to: 'treasures#winners'
  put '/treasures/:id/deactivate', to: 'treasures#deactivate'
end
