Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  # Route to update the status (e.g., toggle completed) of user checklist items
  resources :user_checklist_items, only: [:update]

  # Routes for chat functionality and PDF document uploads
  resources :chats, only: [:index, :show, :new, :create] do
    # Messages are nested within chats as child resources
    resources :messages, only: [:create]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  resource :onboarding, only: [:show, :update]
  resource :profile, only: [:edit, :update, :show]
  resource :dashboard, only: :show

  resources :tasks, only: [:index, :show]
end
