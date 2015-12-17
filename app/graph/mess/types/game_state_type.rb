module Mess
  module Types
    GameStateType = GraphQL::ObjectType.define do
      name 'GameState'
      # interfaces [Mess::NodeIdentification.interface]
      # global_id_field :id
      field :pieces do
        type !types[ Mess::Types::PieceType ]
        resolve -> (obj, ctx, args) { obj["pieces"].map { |key, value| value } }
      end
      field :board do
        type !types.String
        resolve -> (obj, ctx, args) { obj["board"].to_json }
      end
    end
  end
end