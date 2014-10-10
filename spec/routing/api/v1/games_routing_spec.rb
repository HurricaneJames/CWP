require "rails_helper"

RSpec.describe GamesController, :type => :routing do
  describe "routing" do
    it "routes to #available_moves" do
      expect(:get => "/api/v1/games/1/available_moves/2").to route_to("api/v1/games#available_moves", format: 'json', game_id: "1", piece_id: "2")
    end
  end
end
