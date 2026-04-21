Rails.application.routes.draw do
  get "tasks/index"
  get "tasks/show"
  devise_for :users
  root to: "pages#home"
  get "up" => "rails/health#show", as: :rails_health_check

  resources :tasks, only: [:index, :show]
end
