module Mess
  MutationType = GraphQL::ObjectType.define do
    name "Mutations"
    description "The mutation root."

    field :newGame, field: Mess::Mutations::NewGameMutation.field

    field :move, field: Mess::Mutations::MoveMutation.field
  end
end