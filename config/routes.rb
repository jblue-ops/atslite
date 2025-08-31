Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Root route
  root "home#index"

  # Job management routes
  resources :jobs do
    collection do
      get :search
    end
    member do
      patch :publish
      patch :close
      patch :reopen
      patch :archive
      patch :unarchive
    end
  end

  # Job template management routes
  resources :job_templates do
    member do
      patch :activate
      patch :deactivate
      post :use_template
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
