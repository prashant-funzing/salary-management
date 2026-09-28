Rails.application.routes.draw do
  root "home#index"
  get "up" => "rails/health#show", as: :rails_health_check
  namespace :api do
    resources :transfers, only: [ :index, :create ]
    resources :reports, only: :index
    resource :session, only: [ :show, :create, :destroy ]
    resources :employees, only: [ :index, :show, :create, :update ] do
      get :options, on: :collection
      resources :compensations, only: :create
    end
  end
end
