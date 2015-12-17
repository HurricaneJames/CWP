module Mess
  module Types
    GameType = GraphQL::ObjectType.define do
      name 'Game'
      interfaces [Mess::NodeIdentification.interface]

      global_id_field :id

      field :currentState, Mess::Types::GameStateType, property: :current_state
      field :moves, !types.String
    end
  end
end