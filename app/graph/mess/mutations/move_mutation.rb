module Mess
  module Mutations
    MoveMutation = GraphQL::Relay::Mutation.define do
      name "Move"

      input_field :id,   !types.ID
      input_field :from, !types.String
      input_field :to,   !types.String

      return_field :game, Mess::Types::GameType

      resolve -> (input, ctx) {
        game = Mess::NodeIdentification.object_from_id(input['id'], ctx)
        move = "#{input["from"]}:#{input["to"]}:"
        did_move = game.move(move)
        game.save if did_move
        # todo - add error handliner that will say why a move failed if it failed
        { game: game }
      }
    end
  end
end