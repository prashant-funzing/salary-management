Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  namespace :api do
    resource :session, only: [ :show, :create, :destroy ]
    resources :employees, only: [ :index, :show, :create, :update ] do
      get :options, on: :collection
    end
  end
end
