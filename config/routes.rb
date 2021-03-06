Droom::Engine.routes.draw do
  root to: "dashboard#index", as: :dashboard

  match '/suggestions'  => 'suggestions#index', as: "suggestions", via: [:get, :options]
  match '/suggestions/:type'  => 'suggestions#index', via: [:get, :options]

  namespace :api, defaults: {format: 'json'}, constraints: {format: /(json|xml)/} do
    get '/authenticate/:tok' => 'users#authenticate', as: 'authenticate'
    get '/deauthenticate/:tok' => 'users#deauthenticate', as: 'deauthenticate'
    post '/reindex_user' => 'users#reindex_user', as: 'reindex'
    resources :users
    resources :events
    resources :venues
  end

  devise_for :users, class_name: 'Droom::User', module: :devise, controllers: {confirmations: 'droom/users/confirmations', sessions: 'droom/users/sessions', passwords: 'droom/users/passwords'}

  # intermediate confirmation step to allow invitation without setting a password
  devise_scope :user do
    get "/users/:id/welcome/:confirmation_token" => "users/confirmations#show", as: :welcome
    patch "/users/:id/confirm" => "users/confirmations#update", as: :confirm_password
    get "/users/passwords/show" => "users/passwords#show", as: :show_confirmation
    get "/users/passwords/completed" => "users/passwords#completed", as: :complete_confirmation
  end

  resources :services do
    resources :permissions
  end

  resources :preferences
  resources :invitations
  resources :memberships
  resources :scraps
  resources :enquiries do
    get "test", on: :collection
  end

  resources :calendars, only: [:show]
  resources :events do
    get "calendar", on: :collection
    resources :invitations do
      member do
        put :accept
        put :refuse
        put :toggle
      end
    end
    resources :group_invitations
    resources :documents
    resources :agenda_categories
  end

  resources :documents do
    get "suggest", on: :collection
  end
  resources :folders do
    get "dropbox", on: :member, as: :dropbox
    resources :documents
    resources :folders
  end

  resources :organisations do
    resources :users
  end

  resources :users do
    get "preview" => "users#preview", as: :preview_profile
    get "activity" => "users#activity", as: :activity
    get "preferences", on: :member, as: :preferences
    get "admin", on: :collection
    put :set_password, on: :collection
    resources :events
    resources :emails
    resources :phones
    resources :addresses
  end

  resources :groups do
    resources :memberships
    resources :group_permissions
  end

  resources :event_types
  resources :venues

  resources :dropbox_tokens do
    get "/register", on: :collection, action: :create
  end

  put "/set_password" => "users#set_password", as: :set_my_password
  get "/enquire" => "enquiries#new", as: :enquire
  get "/noticeboard" => "scraps#index", as: :noticeboard
  get "/profile" => "users#edit", as: :profile, defaults: {view: "profile"}

end
