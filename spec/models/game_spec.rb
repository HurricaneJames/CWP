require 'rails_helper'

def valid_game_board_state_with_pieces
  # this test should not know this much about the structure of the board
  # replace this with a board builder service/fabricator
  # service/fabricator.add_piece(type: :pawn, x: [x], y: [y])
  {
    pieces: {
      0 => { name: "pawn"   },
      1 => { name: "rook"   },
      2 => { name: "knight" },
      3 => { name: "bishop" },
      4 => { name: "queen"  },
      5 => { name: "king"   }
    },
    board: {
      "2,4" => 0,
      "3,4" => 1,
      "4,4" => 2,
      "2,5" => 3,
      "3,5" => 4,
      "4,5" => 5
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
    expect(game.on_board?({ x:  7, y:  7 })).to be_truthy
    expect(game.on_board?({ x:  8, y:  8 })).to be_falsey
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
    expect(game.piece_on_tile({ x: 3, y: 4 })[:state]).to eq('3,4')
    game.add_piece(name: "pawn", x: 3, y: 5, orientation: -1)
    expect(game.piece_on_tile({ x: 3, y: 5 })[:name]).to eq("pawn")
    expect(game.piece_on_tile({ x: 3, y: 5 })[:orientation]).to eq(-1)
  end

  it "should be able to kill a piece" do
    game = Fabricate.build(:game)
    game.add_piece(name: "pawn", x: 1, y: 1, orientation: 1)
    game.kill_piece("0")
    expect(game.piece_on_tile({ x: 1, y: 1 })).to eq(:none)
    expect(game.pieces["0"][:state]).to eq(:dead)
  end

  it "should be able to remove a piece from the board" do
    game = Fabricate.build(:game)
    game.add_piece(name: "pawn", x: 3, y: 4)
    expect(game.remove_piece(x: 3, y: 4)).to eq({ "id" => "0", "name" => "pawn", "orientation" => 1, "state" => "" })
    expect(game.piece_on_tile(x: 3, y: 4)).to eq(:none)
  end

  it "should be able to tell if a move is legal" do
    game = Fabricate.build(:game, current_state: valid_game_board_state_with_pieces)
    game.add_piece(name: "pawn", x: 3, y: 0)
    expect(game.is_legal?(piece_id: 6, to: { x: 3, y: 1 })).to be_truthy
  end

  it "should be able to give a list of all valid moves" do
    game = Fabricate.build(:game)
    game.add_piece(name: "pawn", x: 3, y: 3)
    valid_pawn_moves = [
      { x: 2, y: 4, orientation: 1 },
      { x: 3, y: 4, orientation: 1 },
      { x: 4, y: 4, orientation: 1 }
    ]
    expect(game.all_legal_moves_for_piece(0)).to match_array(valid_pawn_moves)
  end

  it "should be able to move a piece" do
    game = Fabricate.build(:game)
    game.add_piece(name: "pawn", x: 3, y: 3)
    game.move_piece(from: {x: 3, y: 3}, to: { x: 3, y: 4 })
    expect(game.piece_on_tile({ x: 3, y: 3 })).to eq(:none)
    expect(game.piece_on_tile({ x: 3, y: 4 })[:name]).to eq("pawn")
  end

  it "should be able to move a piece based on move syntax (x,y:x',y')" do
    game = Fabricate.build(:game)
    game.add_piece(name: "pawn", x: 3, y: 3)
    game.move('3,3:3,4')
    expect(game.piece_on_tile({ x: 3, y: 3 })).to eq(:none)
    expect(game.piece_on_tile({ x: 3, y: 4 })[:name]).to eq("pawn")
  end

  it "should track moves" do
    game = Fabricate.build(:game)
    game.add_piece(name: "pawn", x: 3, y: 3)
    game.add_piece(name: "pawn", x: 2, y: 5, orientation: -1)
    game.move('3,3:3,4')
    game.move('2,5:2,4')
    game.move('3,4:3,5')
    expect(game.moves).to eq('3,3:3,4;2,5:2,4;3,4:3,5;')
  end

  describe "collisions" do
    before(:each) do
      test_values = [0.2, 0.4, 0.3, 0.7, 0.9, 0.5, 0.1, 0.6, 0.8]
      allow(Random).to receive(:rand).and_return(*test_values)
    end
    pending "should validate a winnder from the move syntax without doing any conflict resolution"
    it "should be able to determine a winner" do
      game = Fabricate.build(:game)
      game.add_piece(name: "pawn", x: 3, y: 3, orientation:  1)
      game.add_piece(name: "pawn", x: 4, y: 4, orientation: -1)
      game.move('3,3:4,4')
      expect(game.piece_on_tile({ x: 4, y: 4 })).to eq({"id" => "0", "name" => "pawn", "orientation" => 1, "state" => "4,4" })
      expect(game.pieces["1"][:state]).to  eq(:dead)
    end
    it "should get the results of an attack on a tile" do
      game = Fabricate.build(:game)
      game.add_piece(name: "pawn", x: 3, y: 3, orientation:  1)
      game.add_piece(name: "pawn", x: 4, y: 4, orientation: -1)
      expect(game.get_results_of_moving_piece("0", { x: 4, y: 4 })).to eq([{"id"=>"1", "name"=>"pawn", "orientation"=>-1, "state" => "4,4"}])
    end
    it "should handle the results of an attack on a tile that is several pieces away" do
      game = Fabricate.build(:game)
      game.add_rule("juggernaut", GameRule.new({ direction: :forward, collisions: :all, result: [1.0] }))
      game.add_piece(name: "juggernaut", x: 3, y: 3, orientation:  1)
      game.add_piece(name: "pawn", x: 3, y: 4, orientation: -1)
      game.add_piece(name: "pawn", x: 3, y: 5, orientation: -1)
      game.add_piece(name: "pawn", x: 3, y: 6, orientation: -1)
      expected_results = [
        {"id"=>"1", "name"=>"pawn", "orientation"=>-1, "state" => "3,4" },
        {"id"=>"2", "name"=>"pawn", "orientation"=>-1, "state" => "3,5" },
        {"id"=>"3", "name"=>"pawn", "orientation"=>-1, "state" => "3,6" },
      ]
      expect(game.get_results_of_moving_piece("0", { x: 3, y: 7})).to eq(expected_results)
    end
    it "should stop returning results when the attacking piece is dead" do
      game = Fabricate.build(:game)
      game.add_rule("charger", GameRule.new({ direction: :forward, collisions: :all, result: [0.5, 0.25, 0.1, 0.0] }))
      game.add_piece(name: "charger", x: 3, y: 3, orientation:  1)
      game.add_piece(name: "pawn", x: 3, y: 4, orientation: -1)
      game.add_piece(name: "pawn", x: 3, y: 5, orientation: -1)
      game.add_piece(name: "pawn", x: 3, y: 6, orientation: -1)
      expected_results = [
        {"id"=>"1", "name"=>"pawn",    "orientation"=>-1, "state" => "3,4"},
        {"id"=>"0", "name"=>"charger", "orientation"=> 1, "state" => "3,3"},
      ]
      expect(game.get_results_of_moving_piece("0", { x: 3, y: 7})).to eq(expected_results)
    end
  end

  describe "taking turns" do
    it "should allow a move on that side's turn" do
      game = Fabricate.build(:game)
      game.add_piece(name: "pawn", x: 0, y: 1, orientation:  1)
      game.add_piece(name: "pawn", x: 0, y: 6, orientation: -1)
      expect(game.move('0,1:0,2')).to be_truthy
      expect(game.move('0,6:0,5')).to be_truthy
    end

    it "should not allow a move for the wrong side's turn" do
      game = Fabricate.build(:game)
      game.add_piece(name: "pawn", x: 0, y: 1, orientation:  1)
      game.add_piece(name: "pawn", x: 0, y: 6, orientation: -1)
      expect(game.move('0,6:0,5')).to be_falsey
      expect(game.move('0,1:0,2')).to be_truthy
      expect(game.move('0,2:0,3')).to be_falsey
      expect(game.move('0,6:0,5')).to be_truthy
    end
  end
end
