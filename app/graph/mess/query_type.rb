module Mess
  QueryType = GraphQL::ObjectType.define do
    name "Queries"
    description "The query root."

    field :node, field: Mess::NodeIdentification.field

    connection :games, -> { Mess::Types::GameConnection } do
      resolve -> (obj, args, ctx) {
        Game.all
      }
    end
  end
end