Rails.application.routes.draw do
  get "user_checklist_items/update"
  devise_for :users
  root to: "pages#home"

  resources :tasks, only: [:index, :show]
  resources :user_checklist_items, only: [:update]
end
