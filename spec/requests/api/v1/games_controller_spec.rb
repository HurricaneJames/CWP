require 'rails_helper'

describe Api::V1::GamesController do
  let(:url)                { "/api/v1/games" }
  let(:weak_probability)   { 0.25 }
  let(:strong_probability) { 0.9  }

  it "should return all moves available for a piece in the game" do
    game = Game.new
    game.add_piece(name: "pawn", x: 3, y: 3)
    game.save

    get "#{url}/#{game.id}/available_moves/0", format: :json
    expect(response.status).to eq(200)
    expect(JSON.parse response.body).to match_array([
      { "x"=>3, "y"=>4, "orientation"=>1, "probability"=>weak_probability },
      { "x"=>2, "y"=>4, "orientation"=>1, "probability"=>strong_probability },
      { "x"=>4, "y"=>4, "orientation"=>1, "probability"=>strong_probability }
    ])
  end
end
