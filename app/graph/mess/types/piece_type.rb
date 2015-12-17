module Mess
  module Types
    PieceType = GraphQL::ObjectType.define do
      name 'Piece'

      field :id do
        type !types.String
        resolve -> (obj, args, ctx) { obj["id"] }
      end
      field :name do
        type !types.String
        resolve -> (obj, args, ctx) { obj["name"] }
      end
      field :orientation do
        type !types.String
        resolve -> (obj, args, ctx) { obj["orientation"] }
      end
      field :state do
        type !types.String
        resolve -> (obj, args, ctx) { obj["state"] }
      end
    end
  end
end