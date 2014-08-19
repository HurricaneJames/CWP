require 'rails_helper'

def valid_game_board_state_with_pieces
  # this test should not know this much about the structure of the board
  # replace this with a board builder service/fabricator
  # service/fabricator.add_piece(type: :pawn, x: [x], y: [y])
  {
    pieces: {
      1 => { name: "pawn"   },
      2 => { name: "rook"   },
      3 => { name: "knight" },
      4 => { name: "bishop" },
      5 => { name: "queen"  },
      6 => { name: "king"   }
    },
    board: {
      "2,4" => 1,
      "3,4" => 2,
      "4,4" => 3,
      "2,5" => 4,
      "3,5" => 5,
      "4,5" => 6
    }
  }.to_json
end

RSpec.describe Game, :type => :model do
  describe "Validations" do
    pending "Write some validation tests, specifically current_state requires a board and pieces"
  end

  it "should know if a position is on the board" do
    game = Fabricate.build(:game)
    expect(game.on_board?({ x:  0, y:  0 })).to be_truthy
    expect(game.on_board?({ x:  8, y:  8 })).to be_truthy
    expect(game.on_board?({ x:  9, y:  9 })).to be_falsey
    expect(game.on_board?({ x: -1, y: -1 })).to be_falsey
  end

  it "should be able to tell which piece is on a tile" do
    game = Fabricate.build(:game, current_state: valid_game_board_state_with_pieces)
    expect(game.piece_on_tile({ x: 2, y: 4 })[:name]).to eq("pawn")
    expect(game.piece_on_tile({ x: 4, y: 5 })[:name]).to eq("king")
    expect(game.piece_on_tile({ x: 1, y: 1 })).to eq(:none)
    expect(game.piece_on_tile({ x: 9, y: 9 })).to eq(:off_board)
  end

  it "should be able to add a piece to the board" do
    game = Fabricate.build(:game)
    game.add_piece(name: "pawn", x: 3, y: 4)
    expect(game.piece_on_tile({ x: 3, y: 4 })[:name]).to eq("pawn")
  end
end
