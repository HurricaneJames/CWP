module Mess
  Schema = GraphQL::Schema.new(query: Mess::QueryType, mutation: Mess::MutationType)
end