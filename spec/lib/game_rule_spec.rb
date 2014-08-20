require 'rails_helper'

# require 'game_rule'

def valid_rule_description
  { direction: :forward }
end

def valid_game_board_state_with_collisions
  # TODO
  # this test should not know this much about the structure of the board
  # replace this with a board builder service/fabricator
  # service/fabricator.add_piece(type: :pawn, x: [x], y: [y])
  {
    pieces: {
      1 => { name: :pawn },
      2 => { name: :pawn },
      3 => { name: :pawn },
      4 => { name: :pawn },
      5 => { name: :pawn },
      6 => { name: :pawn },
      7 => { name: :pawn },
      8 => { name: :pawn },
      9 => { name: :pawn },
      10 => { name: :pawn },
      11 => { name: :pawn },
      12 => { name: :pawn },
      13 => { name: :pawn },
      14 => { name: :pawn },
      15 => { name: :pawn },
      16 => { name: :pawn }
    },
    board: {
      "2,4" => 1,
      "3,4" => 2,
      "4,4" => 3,
      "2,5" => 4,
      "3,5" => 5,
      "4,5" => 6,
      "2,2" => 7,
      "3,2" => 8,
      "4,2" => 9,
      "2,1" => 10,
      "3,1" => 11,
      "4,1" => 12,
      "2,3" => 13,
      "1,3" => 14,
      "4,3" => 15,
      "5,3" => 16
    }
  }.to_json
end

RSpec.describe GameRule do
  before(:all) do
    @game = Fabricate.build(:game)
    @game_with_collisions = Fabricate.build(:game, current_state: valid_game_board_state_with_collisions)
    @default_start_position = { x: 3, y: 3, orientation:  1 }.freeze
    @inverse_start_position = { x: 3, y: 3, orientation: -1 }.freeze
  end

  describe "creation" do
    it "should create a new rule when given a valid rule description" do
      expect(GameRule.new(valid_rule_description)).to_not be_nil
    end

    it "should require a direction" do
      expect { GameRule.new }.to raise_error
      expect { GameRule.new({}) }.to raise_error("Invalid Rule: Must have a direction specified.")
    end
  end # of creation

  describe "is_valid?" do
    describe "parameters" do
      before(:all) do
        @rule = GameRule.new({ direction: :forward, steps: 1 })
        @valid_to = { x: 1, y: 1 }
        @valid_from = { x: 1, y: 0, orientation: 1 }
      end

      it "should require x/y points for to/from" do
        expect { @rule.is_valid?(on: @game, to: @valid_to, from: { }) }.to raise_error(ArgumentError, "from must include x, y, and orientation.")
        expect { @rule.is_valid?(on: @game, to: @valid_to, from: { x: 1, orientation: 1 }) }.to raise_error(ArgumentError, "from must include x, y, and orientation.")
        expect { @rule.is_valid?(on: @game, to: @valid_to, from: { y: 1, orientation: 1 }) }.to raise_error(ArgumentError, "from must include x, y, and orientation.")
        expect { @rule.is_valid?(on: @game, to: { }, from: @valid_from) }.to raise_error(ArgumentError, "to must include x and y points.")
        expect { @rule.is_valid?(on: @game, to: { x: 1 }, from: @valid_from) }.to raise_error(ArgumentError, "to must include x and y points.")
        expect { @rule.is_valid?(on: @game, to: { y: 1 }, from: @valid_from) }.to raise_error(ArgumentError, "to must include x and y points.")
      end

      it "should require orientation for from position" do
        expect { @rule.is_valid?(on: @game, to: @valid_to, from: { x: 1, y: 0 }) }.to raise_error(ArgumentError, "from must include x, y, and orientation.")
      end

      it "should require a game board to validate against" do
        expect { @rule.is_valid?(on: nil, to: @valid_to, from: @valid_from) }.to raise_error(ArgumentError, "on must be a game model.")
      end

      it "should reject any move where from/to are not on the board" do
        expect(@rule.is_valid?(on: @game, to: @valid_to, from: { x: -1, y: 0, orientation: 1 })).to be_falsey
      end
    end

    describe "where rules have a fixed number of steps," do
      describe "forward validation" do
        before(:all) do
          @rule = GameRule.new({ direction: :forward, steps: 1 })
        end
        it "should approve valid moves" do
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 0, orientation:  1 }, to: { x: 0, y: 1 })).to be_truthy
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 1, orientation: -1 }, to: { x: 0, y: 0 })).to be_truthy
        end
        it "should reject moves with too many steps" do
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 0, orientation: 1 }, to: { x: 0, y: 2 })).to be_falsey
        end
        it "should reject moves with too few steps" do
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 0, orientation: 1 }, to: { x: 0, y: 0 })).to be_falsey
          rule_with_two_steps = GameRule.new({ direction: :forward, steps: 2 })
          expect(rule_with_two_steps.is_valid?(on: @game , from: { x: 0, y: 0, orientation: 1 }, to: { x: 0, y: 1 })).to be_falsey
        end
        it "should reject opposite moves" do
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 1, orientation:  1 }, to: { x: 0, y: 0 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 1, orientation: -1 }, to: { x: 0, y: 2 })).to be_falsey
        end
        it "should reject diagonal moves" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 2, y: 4 })).to be_falsey
        end
      end

      describe "backward validation" do
        before(:all) do
          @rule = GameRule.new({ direction: :backward, steps: 1 })
        end
        it "should approve valid moves" do
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 1, orientation:  1 }, to: { x: 0, y: 0 })).to be_truthy
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 0, orientation: -1 }, to: { x: 0, y: 1 })).to be_truthy
        end
        it "should reject moves with too many steps" do
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 2, orientation: 1 }, to: { x: 0, y: 0 })).to be_falsey
        end
        it "should reject moves with too few steps" do
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 1, orientation: 1 }, to: { x: 0, y: 1 })).to be_falsey
          rule_with_two_steps = GameRule.new({ direction: :backward, steps: 2 })
          expect(rule_with_two_steps.is_valid?(on: @game , from: { x: 0, y: 2, orientation: 1 }, to: { x: 0, y: 1 })).to be_falsey
        end
        it "should reject opposite moves" do
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 1, orientation:  1 }, to: { x: 0, y: 2 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 1, orientation: -1 }, to: { x: 0, y: 0 })).to be_falsey
        end
        it "should reject diagonal moves" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 2, y: 2 })).to be_falsey
        end
      end

      describe "left validation" do
        before(:all) do
          @rule = GameRule.new({ direction: :left, steps: 1 })
        end
        it "should approve valid moves" do
          expect(@rule.is_valid?(on: @game, from: { x: 1, y: 0, orientation:  1 }, to: { x: 0, y: 0 })).to be_truthy
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 0, orientation: -1 }, to: { x: 1, y: 0 })).to be_truthy
        end
        it "should reject moves with too many steps" do
          expect(@rule.is_valid?(on: @game, from: { x: 2, y: 0, orientation: 1 }, to: { x: 0, y: 0 })).to be_falsey
        end
        it "should reject moves with too few steps" do
          expect(@rule.is_valid?(on: @game, from: { x: 2, y: 0, orientation: 1 }, to: { x: 2, y: 0 })).to be_falsey
          rule_with_two_steps = GameRule.new({ direction: :left, steps: 2 })
          expect(rule_with_two_steps.is_valid?(on: @game , from: { x: 2, y: 0, orientation: 1 }, to: { x: 1, y: 0 })).to be_falsey
        end
        it "should reject opposite moves" do
          expect(@rule.is_valid?(on: @game, from: { x: 2, y: 0, orientation:  1 }, to: { x: 3, y: 0 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: { x: 2, y: 0, orientation: -1 }, to: { x: 1, y: 0 })).to be_falsey
        end
        it "should reject diagonal moves" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 2, y: 4 })).to be_falsey
        end
      end

      describe "right validation" do
        before(:all) do
          @rule = GameRule.new({ direction: :right, steps: 1 })
        end
        it "should approve valid moves" do
          expect(@rule.is_valid?(on: @game, from: { x: 2, y: 0, orientation:  1 }, to: { x: 3, y: 0 })).to be_truthy
          expect(@rule.is_valid?(on: @game, from: { x: 2, y: 0, orientation: -1 }, to: { x: 1, y: 0 })).to be_truthy
        end
        it "should reject moves with too many steps" do
          expect(@rule.is_valid?(on: @game, from: { x: 2, y: 0, orientation: 1 }, to: { x: 4, y: 0 })).to be_falsey
        end
        it "should reject moves with too few steps" do
          expect(@rule.is_valid?(on: @game, from: { x: 2, y: 0, orientation: 1 }, to: { x: 2, y: 0 })).to be_falsey
          rule_with_two_steps = GameRule.new({ direction: :right, steps: 2 })
          expect(rule_with_two_steps.is_valid?(on: @game , from: { x: 2, y: 0, orientation: 1 }, to: { x: 3, y: 0 })).to be_falsey
        end
        it "should reject opposite moves" do
          expect(@rule.is_valid?(on: @game, from: { x: 2, y: 0, orientation:  1 }, to: { x: 1, y: 0 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: { x: 2, y: 0, orientation: -1 }, to: { x: 3, y: 0 })).to be_falsey
        end
        it "should reject diagonal moves" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 4, y: 4 })).to be_falsey
        end
      end

      describe "forward-left validation" do
        before(:all) do
          @rule = GameRule.new({ direction: :diagonal_forward_left, steps: 1 })
        end
        it "should approve valid moves" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 2, y: 4 })).to be_truthy
          expect(@rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 4, y: 2 })).to be_truthy
        end
        it "should reject moves with too many steps" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 1, y: 5 })).to be_falsey
        end
        it "should reject moves with too few steps" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 3, y: 3 })).to be_falsey
          rule_with_two_steps = GameRule.new({ direction: :diagonal_forward_left, steps: 2 })
          expect(rule_with_two_steps.is_valid?(on: @game , from: { x: 3, y: 0, orientation: 1 }, to: { x: 2, y: 1 })).to be_falsey
        end
        it "should reject other diagonals moves" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 4, y: 4 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 4, y: 2 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 2, y: 2 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 2, y: 4 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 4, y: 4 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 2, y: 2 })).to be_falsey
        end
        it "should reject non-diagonal moves" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 3, y: 4 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 3, y: 2 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 4, y: 3 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 2, y: 3 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 4, y: 5 })).to be_falsey
        end
      end

      describe "forward-right validation" do
        before(:all) do
          @rule = GameRule.new({ direction: :diagonal_forward_right, steps: 1 })
        end
        it "should approve valid moves" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 4, y: 4 })).to be_truthy
          expect(@rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 2, y: 2 })).to be_truthy
        end
        it "should reject moves with too many steps" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 5, y: 5 })).to be_falsey
        end
        it "should reject moves with too few steps" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 3, y: 3 })).to be_falsey
          rule_with_two_steps = GameRule.new({ direction: :diagonal_forward_right, steps: 2 })
          expect(rule_with_two_steps.is_valid?(on: @game , from: @default_start_position, to: { x: 4, y: 4 })).to be_falsey
        end
        it "should reject other diagonals moves" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 2, y: 4 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 4, y: 2 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 2, y: 2 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 2, y: 4 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 4, y: 4 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 4, y: 2 })).to be_falsey
        end
        it "should reject non-diagonal moves" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 3, y: 4 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 3, y: 2 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 4, y: 3 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 2, y: 3 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 4, y: 5 })).to be_falsey
        end
      end

      describe "backward-left validation" do
        before(:all) do
          @rule = GameRule.new({ direction: :diagonal_backward_left, steps: 1 })
        end
        it "should approve valid moves" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 2, y: 2 })).to be_truthy
          expect(@rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 4, y: 4 })).to be_truthy
        end
        it "should reject moves with too many steps" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 1, y: 1 })).to be_falsey
        end
        it "should reject moves with too few steps" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 3, y: 3 })).to be_falsey
          rule_with_two_steps = GameRule.new({ direction: :diagonal_backward_left, steps: 2 })
          expect(rule_with_two_steps.is_valid?(on: @game , from: @default_start_position, to: { x: 2, y: 2 })).to be_falsey
        end
        it "should reject other diagonals moves" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 4, y: 4 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 4, y: 2 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 2, y: 4 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 2, y: 4 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 4, y: 2 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 2, y: 2 })).to be_falsey
        end
        it "should reject non-diagonal moves" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 3, y: 4 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 3, y: 2 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 4, y: 3 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 2, y: 3 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 4, y: 5 })).to be_falsey
        end
      end

      describe "backward-right validation" do
        before(:all) do
          @rule = GameRule.new({ direction: :diagonal_backward_right, steps: 1 })
        end
        it "should approve valid moves" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 4, y: 2 })).to be_truthy
          expect(@rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 2, y: 4 })).to be_truthy
        end
        it "should reject moves with too many steps" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 1, y: 5 })).to be_falsey
        end
        it "should reject moves with too few steps" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 3, y: 3 })).to be_falsey
          rule_with_two_steps = GameRule.new({ direction: :diagonal_backward_right, steps: 2 })
          expect(rule_with_two_steps.is_valid?(on: @game , from: @default_start_position, to: { x: 4, y: 2 })).to be_falsey
        end
        it "should reject other diagonals moves" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 4, y: 4 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 2, y: 4 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 2, y: 2 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 4, y: 2 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 4, y: 4 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 2, y: 2 })).to be_falsey
        end
        it "should reject non-diagonal moves" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 3, y: 4 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 3, y: 2 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 4, y: 3 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 2, y: 3 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 4, y: 5 })).to be_falsey
        end
      end
    end

    describe "where moves have a range of steps," do
      describe "forward validation" do
        before(:all) do
          @rule = GameRule.new({ direction: :forward })
        end
        it "should approve valid moves" do
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 0, orientation:  1 }, to: { x: 0, y: 1 })).to be_truthy
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 0, orientation:  1 }, to: { x: 0, y: 5 })).to be_truthy
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 6, orientation: -1 }, to: { x: 0, y: 5 })).to be_truthy
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 6, orientation: -1 }, to: { x: 0, y: 0 })).to be_truthy
        end
        it "should reject opposite moves" do
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 1, orientation:  1 }, to: { x: 0, y: 0 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 6, orientation: -1 }, to: { x: 0, y: 7 })).to be_falsey
        end
        it "should reject diagonal moves" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 2, y: 4 })).to be_falsey
        end
        it "should reject moves with too many collisions" do
          expect(@rule.is_valid?(on: @game_with_collisions, from: @default_start_position, to: { x: 3, y: 5 })).to be_falsey
        end
      end
      describe "backward validation" do
        before(:all) do
          @rule = GameRule.new({ direction: :backward })
        end
        it "should approve valid moves" do
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 5, orientation:  1 }, to: { x: 0, y: 4 })).to be_truthy
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 5, orientation:  1 }, to: { x: 0, y: 1 })).to be_truthy
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 1, orientation: -1 }, to: { x: 0, y: 2 })).to be_truthy
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 1, orientation: -1 }, to: { x: 0, y: 5 })).to be_truthy
        end
        it "should reject opposite moves" do
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 3, orientation:  1 }, to: { x: 0, y: 6 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: { x: 0, y: 3, orientation: -1 }, to: { x: 0, y: 1 })).to be_falsey
        end
        it "should reject diagonal moves" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 2, y: 2 })).to be_falsey
        end
        it "should reject moves with too many collisions" do
          expect(@rule.is_valid?(on: @game_with_collisions, from: @default_start_position, to: { x: 3, y: 0 })).to be_falsey
        end
      end
      describe "left validation" do
        before(:all) do
          @rule = GameRule.new({ direction: :left })
        end
        it "should approve valid moves" do
          expect(@rule.is_valid?(on: @game, from: { x: 3, y: 0, orientation:  1 }, to: { x: 2, y: 0 })).to be_truthy
          expect(@rule.is_valid?(on: @game, from: { x: 3, y: 0, orientation:  1 }, to: { x: 0, y: 0 })).to be_truthy
          expect(@rule.is_valid?(on: @game, from: { x: 3, y: 0, orientation: -1 }, to: { x: 4, y: 0 })).to be_truthy
          expect(@rule.is_valid?(on: @game, from: { x: 3, y: 0, orientation: -1 }, to: { x: 7, y: 0 })).to be_truthy
        end
        it "should reject opposite moves" do
          expect(@rule.is_valid?(on: @game, from: { x: 3, y: 0, orientation:  1 }, to: { x: 7, y: 0 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: { x: 3, y: 0, orientation: -1 }, to: { x: 0, y: 0 })).to be_falsey
        end
        it "should reject diagonal moves" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 2, y: 4 })).to be_falsey
        end
        it "should reject moves with too many collisions" do
          expect(@rule.is_valid?(on: @game_with_collisions, from: @default_start_position, to: { x: 1, y: 3 })).to be_falsey
        end
      end
      describe "right validation" do
        before(:all) do
          @rule = GameRule.new({ direction: :right })
        end
        it "should approve valid moves" do
          expect(@rule.is_valid?(on: @game, from: { x: 3, y: 0, orientation:  1 }, to: { x: 4, y: 0 })).to be_truthy
          expect(@rule.is_valid?(on: @game, from: { x: 3, y: 0, orientation:  1 }, to: { x: 7, y: 0 })).to be_truthy
          expect(@rule.is_valid?(on: @game, from: { x: 3, y: 0, orientation: -1 }, to: { x: 2, y: 0 })).to be_truthy
          expect(@rule.is_valid?(on: @game, from: { x: 3, y: 0, orientation: -1 }, to: { x: 0, y: 0 })).to be_truthy
        end
        it "should reject opposite moves" do
          expect(@rule.is_valid?(on: @game, from: { x: 3, y: 0, orientation:  1 }, to: { x: 0, y: 0 })).to be_falsey
          expect(@rule.is_valid?(on: @game, from: { x: 3, y: 0, orientation: -1 }, to: { x: 7, y: 0 })).to be_falsey
        end
        it "should reject diagonal moves" do
          expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 4, y: 4 })).to be_falsey
        end
        it "should reject moves with too many collisions" do
          expect(@rule.is_valid?(on: @game_with_collisions, from: @default_start_position, to: { x: 5, y: 3 })).to be_falsey
        end
      end

      describe "diagonal validation" do
        it "should approve valid forward-left moves" do
          rule = GameRule.new({ direction: :diagonal_forward_left })
          expect(rule.is_valid?(on: @game, from: @default_start_position, to: { x: 2, y: 4 })).to be_truthy
          expect(rule.is_valid?(on: @game, from: @default_start_position, to: { x: 1, y: 5 })).to be_truthy
          expect(rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 4, y: 2 })).to be_truthy
          expect(rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 5, y: 1 })).to be_truthy
          expect(rule.is_valid?(on: @game_with_collisions, from: @default_start_position, to: { x: 1, y: 5 })).to be_falsey
        end
        it "should approve valid forward-right moves" do
          rule = GameRule.new({ direction: :diagonal_forward_right })
          expect(rule.is_valid?(on: @game, from: @default_start_position, to: { x: 4, y: 4 })).to be_truthy
          expect(rule.is_valid?(on: @game, from: @default_start_position, to: { x: 5, y: 5 })).to be_truthy
          expect(rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 2, y: 2 })).to be_truthy
          expect(rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 1, y: 1 })).to be_truthy
          expect(rule.is_valid?(on: @game_with_collisions, from: @default_start_position, to: { x: 5, y: 5 })).to be_falsey
        end
        it "should approve valid backward-left moves" do
          rule = GameRule.new({ direction: :diagonal_backward_left })
          expect(rule.is_valid?(on: @game, from: @default_start_position, to: { x: 2, y: 2 })).to be_truthy
          expect(rule.is_valid?(on: @game, from: @default_start_position, to: { x: 1, y: 1 })).to be_truthy
          expect(rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 4, y: 4 })).to be_truthy
          expect(rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 5, y: 5 })).to be_truthy
          expect(rule.is_valid?(on: @game_with_collisions, from: @default_start_position, to: { x: 1, y: 1 })).to be_falsey
        end
        it "should approve valid backward-right moves" do
          rule = GameRule.new({ direction: :diagonal_backward_right })
          expect(rule.is_valid?(on: @game, from: @default_start_position, to: { x: 4, y: 2 })).to be_truthy
          expect(rule.is_valid?(on: @game, from: @default_start_position, to: { x: 5, y: 1 })).to be_truthy
          expect(rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 2, y: 4 })).to be_truthy
          expect(rule.is_valid?(on: @game, from: @inverse_start_position, to: { x: 1, y: 5 })).to be_truthy
          expect(rule.is_valid?(on: @game_with_collisions, from: @default_start_position, to: { x: 5, y: 1 })).to be_falsey
        end
      end
    end

    describe "when the move involves a collision," do
      it "should approve moves for those rules that specifically disable collisions" do
        rule_with_collisions_disabled = GameRule.new({ direction: :forward, collisions: :disabled })
        expect(rule_with_collisions_disabled.is_valid?(on: @game_with_collisions, from: @default_start_position, to: { x: 3, y: 4 })).to be_truthy
        expect(rule_with_collisions_disabled.is_valid?(on: @game_with_collisions, from: @default_start_position, to: { x: 3, y: 5 })).to be_truthy
        expect(rule_with_collisions_disabled.is_valid?(on: @game_with_collisions, from: @default_start_position, to: { x: 3, y: 6 })).to be_truthy
      end
      it "should approve moves for those rules that allow collisions with all pieces in the path" do
        rule_with_collisions_disabled = GameRule.new({ direction: :forward, collisions: :all })
        expect(rule_with_collisions_disabled.is_valid?(on: @game_with_collisions, from: @default_start_position, to: { x: 3, y: 4 })).to be_truthy
        expect(rule_with_collisions_disabled.is_valid?(on: @game_with_collisions, from: @default_start_position, to: { x: 3, y: 5 })).to be_truthy
        expect(rule_with_collisions_disabled.is_valid?(on: @game_with_collisions, from: @default_start_position, to: { x: 3, y: 6 })).to be_truthy
      end
      it "should approve moves for those rules that skip collisions with all pieces in the path except the last piece (jumping)" do
        rule_with_collisions_disabled = GameRule.new({ direction: :forward, collisions: :jumping })
        expect(rule_with_collisions_disabled.is_valid?(on: @game_with_collisions, from: @default_start_position, to: { x: 3, y: 4 })).to be_truthy
        expect(rule_with_collisions_disabled.is_valid?(on: @game_with_collisions, from: @default_start_position, to: { x: 3, y: 5 })).to be_truthy
        expect(rule_with_collisions_disabled.is_valid?(on: @game_with_collisions, from: @default_start_position, to: { x: 3, y: 6 })).to be_truthy
      end
      it "should reject moves that have any collisions for those rules that do not allow any collisions" do
        rule_with_no_collisions_allowed = GameRule.new({ direction: :forward, collisions: :none })
        expect(rule_with_no_collisions_allowed.is_valid?(on: @game_with_collisions, from: @default_start_position, to: { x: 3, y: 4 })).to be_falsey
      end
      describe "rules containing collision restrictions" do
        before(:all) do
          @rule = GameRule.new({ direction: :forward, collisions: :blocking })
        end
        it "should approve moves that only involve a single collision" do
          expect(@rule.is_valid?(on: @game_with_collisions, from: @default_start_position, to: { x: 3, y: 4 })).to be_truthy
        end
        it "should reject moves that involve more than one collision" do
          expect(@rule.is_valid?(on: @game_with_collisions, from: @default_start_position, to: { x: 3, y: 5 })).to be_falsey
        end
      end
    end

    describe "when the rule has compound directions," do
      before(:all) do
        @rule = GameRule.new({ direction: [ { direction: :forward,  steps: 2, collisions: :disabled }, { direction: :right,  steps: 1 } ], steps: 1 })
      end
      it "accepts a valid move on compound rules" do
        expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 4, y: 5 })).to be_truthy
      end
      it "rejects invalid moves on compound rules" do
        expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 3, y: 5 })).to be_falsey
        expect(@rule.is_valid?(on: @game, from: @default_start_position, to: { x: 2, y: 5 })).to be_falsey
      end
    end
  end # of is_valid?

  describe "all_valid_moves_from" do
    it "should return valid moves for rules with fixed steps" do
      rule = GameRule.new({ direction: :forward, steps: 1 })
      expect(rule.all_valid_moves(on: @game, from_positions: @default_start_position)).to contain_exactly({ x: 3, y: 4, orientation: 1 })
      rule = GameRule.new({ direction: :forward, steps: 2 })
      expect(rule.all_valid_moves(on: @game, from_positions: @default_start_position)).to contain_exactly({ x: 3, y: 5, orientation: 1 })
      rule = GameRule.new({ direction: :forward, steps: 3 })
      expect(rule.all_valid_moves(on: @game, from_positions: @default_start_position)).to contain_exactly({ x: 3, y: 6, orientation: 1 })
    end
    it "should return valid moves for rules with step ranges" do
      rule = GameRule.new({ direction: :forward, steps: { min: 1, max: 2 }})
      expect(rule.all_valid_moves(on: @game, from_positions: @default_start_position)).to contain_exactly({ x: 3, y: 4, orientation: 1 }, { x: 3, y: 5, orientation: 1 })
    end
    it "should return valid moves for unlimited step rules" do
      rule = GameRule.new({ direction: :forward })
      straight_positions = [ { x: 3, y: 4, orientation: 1 }, { x: 3, y: 5, orientation: 1 }, { x: 3, y: 6, orientation: 1 },
                             { x: 3, y: 7, orientation: 1 }, { x: 3, y: 8, orientation: 1 } ]
      expect(rule.all_valid_moves(on: @game, from_positions: @default_start_position)).to match(straight_positions)
    end
    it "should not return moves with invalid collisions" do
      game = Fabricate.build(:game)
      game.add_piece({ name: "pawn", x: 3, y: 4 })
      rule = GameRule.new({ direction: :forward })
      expect(rule.all_valid_moves(on: @game_with_collisions, from_positions: @default_start_position)).to contain_exactly({ x: 3, y: 4, orientation: 1 })
    end
    describe "on rules with compound directions" do
      it "should return moves that have no collisions" do
        rule = GameRule.new({ direction: [ { direction: :forward,  steps: 2, collisions: :disabled }, { direction: :right,  steps: 1 } ], steps: 1 })
        expect(rule.all_valid_moves(on: @game, from_positions: @default_start_position)).to contain_exactly({ x: 4, y: 5, orientation: 1 })
        rule = GameRule.new({ direction: [ { direction: :forward, collisions: :disabled }, { direction: :right,  steps: 1 } ], steps: 1 })
        interesting_rule_moves = [{:x=>4, :y=>4, :orientation=>1}, {:x=>4, :y=>5, :orientation=>1}, {:x=>4, :y=>6, :orientation=>1}, {:x=>4, :y=>7, :orientation=>1}, {:x=>4, :y=>8, :orientation=>1}]
        expect(rule.all_valid_moves(on: @game, from_positions: @default_start_position)).to match(interesting_rule_moves)
      end
      describe "that involve collisions" do
        it "should return moves with valid collisions" do
          game = Fabricate.build(:game)
          game.add_piece(name: "pawn", x: 3, y: 4)
          game.add_piece(name: "pawn", x: 3, y: 5)
          game.add_piece(name: "pawn", x: 4, y: 5)
          rule = GameRule.new({ direction: [ { direction: :forward,  steps: 2, collisions: :disabled }, { direction: :right,  steps: 1 } ], steps: 1 })
          expect(rule.all_valid_moves(on: game, from_positions: @default_start_position)).to contain_exactly({ x: 4, y: 5, orientation: 1 })
        end
        it "should return moves on rules with weird, and probably unexpected, collisions (blocking causes iteresting effects with compound rules)" do
          game = Fabricate.build(:game)
          game.add_piece(name: "pawn", x: 3, y: 4)
          weird_rule = GameRule.new({ direction: [ { direction: :forward, collisions: :blocking }, { direction: :right,  steps: 1 } ], steps: 1 })
          expected_moves = [{ x: 4, y: 4, orientation: 1 }]
          expect(weird_rule.all_valid_moves(on: game, from_positions: @default_start_position)).to match(expected_moves)
        end
        it "should return valid moves on compound directions (this is probably what was expected)" do
          game = Fabricate.build(:game)
          game.add_piece(name: "pawn", x: 3, y: 4)
          game.add_piece(name: "pawn", x: 3, y: 5)
          rule = GameRule.new({ direction: [ { direction: :forward, collisions: :none }, { direction: :right,  steps: 1 } ], steps: 1 })

          expect(rule.all_valid_moves(on: game, from_positions: @default_start_position)).to match([])
          
          game.remove_piece({ x: 3, y: 4 })
          expected_moves = [{ x: 4, y: 4, orientation: 1 }]
          expect(rule.all_valid_moves(on: game, from_positions: @default_start_position)).to match(expected_moves)
        end
      end
    end
  end
end
