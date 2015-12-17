module Mess
  module Types
    GameConnection = GraphQL::Relay::RelationConnection.create_type(Mess::Types::GameType)
  end
end