module Mess
  module Mutations
    NewGameMutation = GraphQL::Relay::Mutation.define do
      name "NewGame"

      return_field :game, Mess::Types::GameType

      resolve -> (input, ctx) {
        new_game = GameMaster.new_game
        new_game.save!
        { game: new_game }
      }
    end
  end
end