Rails.application.routes.draw do
  # Admin namespace
  constraints ->(request) { Session.find_by(id: request.cookie_jar.signed[:session_id]) } do
    mount MissionControl::Jobs::Engine, at: "/admin/jobs"
  end

  namespace :admin do
    resource :session, only: [ :new, :create, :destroy ]
    root to: "dashboard#show"

    resources :sync_attempts, only: [ :index, :show ]

    resources :chassis do
      member do
        post :sync_variants
      end
      resources :miniatures, only: [ :new, :create, :edit, :update, :destroy ]
    end

    resources :events do
      member do
        patch :activate
        patch :complete
      end
      resources :army_lists, only: [ :index, :show, :destroy ] do
        member do
          patch :unlock
        end
      end
    end
  end

  # Public pages
  root to: "events#index"

  resources :events, only: [ :index, :show ] do
    resources :army_lists, only: [ :new, :create, :show, :edit, :update ] do
      member do
        patch :submit
      end
      resources :army_list_items, only: [ :create, :destroy, :update ]
    end
  end

  resources :variants, only: [] do
    get :card, on: :member, to: "variant_cards#show"
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
