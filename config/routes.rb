Rails.application.routes.draw do
  get '/auth/:provider/callback', to: 'sessions#create'
  get '/sign_out', to: 'sessions#destroy'

  get '/', to: 'workshops#index'
  get '/:workshop/', to: 'workshops#render_workshop'
  get '/:workshop/*file', to: 'workshops#render_file', constraints: { file: /.*/ }

  resources :projects, only: :create do
    get 'validate_github_url', on: :collection
  end
end
