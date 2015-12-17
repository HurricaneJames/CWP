Rails.application.routes.draw do
  match 'graphql', to: 'graphql#exec', via: [:get, :post]
  match 'graphiql', to: 'graphql#graphiql', via: [:get]

  api_version(:module => "Api::V1", :path => {:value => "api/v1"}, defaults: { format: 'json' }) do
    get  '/games/:game_id/available_moves/:piece_id', to: 'games#available_moves', as: 'available_moves'
  end
  resources :games do
    post 'move', on: :member
  end

  root 'games#index'
end
