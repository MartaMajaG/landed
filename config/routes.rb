Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  # Route to update the status (e.g., toggle completed) of user checklist items
  resources :user_checklist_items, only: [:update]

  get "up" => "rails/health#show", as: :rails_health_check


  # Defines the root path route ("/")
  # root "posts#index"
  resources :profiles, only: [:edit, :update, :show]
end
