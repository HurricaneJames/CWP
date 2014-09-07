require 'rails_helper'

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
      1 =>  { name: :pawn, orientation: -1 },
      2 =>  { name: :pawn, orientation: -1 },
      3 =>  { name: :pawn, orientation: -1 },
      4 =>  { name: :pawn, orientation: -1 },
      5 =>  { name: :pawn, orientation: -1 },
      6 =>  { name: :pawn, orientation: -1 },
      7 =>  { name: :pawn, orientation: -1 },
      8 =>  { name: :pawn, orientation: -1 },
      9 =>  { name: :pawn, orientation: -1 },
      10 => { name: :pawn, orientation: -1 },
      11 => { name: :pawn, orientation: -1 },
      12 => { name: :pawn, orientation: -1 },
      13 => { name: :pawn, orientation: -1 },
      14 => { name: :pawn, orientation: -1 },
      15 => { name: :pawn, orientation: -1 },
      16 => { name: :pawn, orientation: -1 }
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

    it "can create a compound rule from an array of rules" do
      r1 = GameRule.new({ direction: :forward, steps: 2 })
      r2 = GameRule.new({ direction: :right, steps: 1 })
      expect(GameRule.new({ direction: [ r1, r2 ], steps: 1 })).to be_present
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
                             { x: 3, y: 7, orientation: 1 } ]
      expect(rule.all_valid_moves(on: @game, from_positions: @default_start_position)).to match_array(straight_positions)
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
        interesting_rule_moves = [
          { x: 4, y: 4, orientation: 1 }, { x: 4, y: 5, orientation: 1 },
          { x: 4, y: 6, orientation: 1 }, { x: 4, y: 7, orientation: 1 }
        ]
        expect(rule.all_valid_moves(on: @game, from_positions: @default_start_position)).to match_array(interesting_rule_moves)
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
        it "should not return any moves that violate :none/:blocking conditions when advancing min steps" do
          game = Fabricate.build(:game)
          game.add_piece(name: "pawn", x: 3, y: 4)
          # game.add_piece(name: "pawn", x: 3, y: 5) # intermediate tile...
          game.add_piece(name: "pawn", x: 4, y: 5)
          rule = GameRule.new({ direction: [ { direction: :forward, collisions: :none, steps: 2 }, { direction: :right,  steps: 1 } ], steps: 1 })

          expect(rule.all_valid_moves(on: game, from_positions: @default_start_position)).to match([])
        end
      end
    end
  end

  describe "all_traveled_tiles" do
    it "should give all tiles traveled by a simple rule" do
      rule = GameRule.new({direction: :forward})
      expected_results = [
        { x: 0, y: 1, orientation: 1, rule_properties: { rule: rule, step: 0 } },
        { x: 0, y: 2, orientation: 1, rule_properties: { rule: rule, step: 1 } }
      ]
      expect(rule.all_traveled_tiles(@game, { x: 0, y: 0, orientation: 1 }, { x: 0, y: 2 })).to match(expected_results)
    end
    it "should give only those tiles traveled when limited by step counts" do
      rule = GameRule.new( { direction: :forward, steps: 2 })
      expected_results = [
        { x: 0, y: 1, orientation: 1, rule_properties: { rule: rule, step: 0 } },
        { x: 0, y: 2, orientation: 1, rule_properties: { rule: rule, step: 1 } }
      ]
      expect(rule.all_traveled_tiles(@game, { x: 0, y: 0, orientation: 1 }, { x: 0, y: 2 })).to match(expected_results)
      expect(rule.all_traveled_tiles(@game, { x: 0, y: 0, orientation: 1 }, { x: 0, y: 1 })).to be_nil
    end
    it "should give all tiles traveled by a compound rule" do
      rule_parts = [ GameRule.new({ direction: :forward,  steps: 2, collisions: :disabled }), GameRule.new({ direction: :right,  steps: 1 }) ]
      rule = GameRule.new({ direction: rule_parts, steps: 1 })
      expected_results = [
        { x: 3, y: 1, orientation: 1, rule_properties: { rule: rule_parts[0], step: 0 } },
        { x: 3, y: 2, orientation: 1, rule_properties: { rule: rule_parts[0], step: 1 } },
        { x: 4, y: 2, orientation: 1, rule_properties: { rule: rule_parts[1], step: 0 } }
      ]
      expect(rule.all_traveled_tiles(@game, { x: 3, y: 0, orientation: 1 }, { x: 4, y: 2 })).to match(expected_results)
    end
    it "should give all tiles traveled by a weird compound rule" do
      rule_parts = [
        GameRule.new({ direction: :forward,  steps: { min: 1, max: 3 }, collisions: :disabled }),
        GameRule.new({ direction: :right,    steps: { min: 1, max: 2 } }),
        GameRule.new({ direction: :backward, steps: 1 })
      ]
      rule = GameRule.new({ direction: rule_parts, steps: 1 })
      expected_results = [
        { x: 3, y: 1, orientation: 1, rule_properties: { rule: rule_parts[0], step: 0 } },
        { x: 3, y: 2, orientation: 1, rule_properties: { rule: rule_parts[0], step: 1 } },
        { x: 3, y: 3, orientation: 1, rule_properties: { rule: rule_parts[0], step: 2 } },
        { x: 4, y: 3, orientation: 1, rule_properties: { rule: rule_parts[1], step: 0 } },
        { x: 4, y: 2, orientation: 1, rule_properties: { rule: rule_parts[2], step: 0 } }
      ]
      expect(rule.all_traveled_tiles(@game, { x: 3, y: 0, orientation: 1 }, { x: 4, y: 2 })).to match(expected_results)
    end
    it "should give a valid walk from point a to point b even when the rule is a weird compound that can actually arrive at the conclusion by more than one sequence" do
      rule_parts = [
        GameRule.new({ direction: :forward,  steps: { min: 1, max: 3 }, collisions: :disabled }),
        GameRule.new({ direction: :right,    steps: { min: 1, max: 2 } }),
        GameRule.new({ direction: :backward, steps: { min: 1, max: 3 } })
      ]
      rule = GameRule.new({ direction: rule_parts, steps: 1 })
      valid_walks = [
        [
          { x: 3, y: 1, orientation: 1, rule_properties: { rule: rule_parts[0], step: 0 } },
          { x: 3, y: 2, orientation: 1, rule_properties: { rule: rule_parts[0], step: 1 } },
          { x: 4, y: 2, orientation: 1, rule_properties: { rule: rule_parts[1], step: 0 } },
          { x: 4, y: 1, orientation: 1, rule_properties: { rule: rule_parts[2], step: 0 } }
        ],
        [
          { x: 3, y: 1, orientation: 1, rule_properties: { rule: rule_parts[0], step: 0 } },
          { x: 3, y: 2, orientation: 1, rule_properties: { rule: rule_parts[0], step: 1 } },
          { x: 3, y: 3, orientation: 1, rule_properties: { rule: rule_parts[0], step: 2 } },
          { x: 4, y: 3, orientation: 1, rule_properties: { rule: rule_parts[1], step: 0 } },
          { x: 4, y: 2, orientation: 1, rule_properties: { rule: rule_parts[2], step: 0 } },
          { x: 4, y: 1, orientation: 1, rule_properties: { rule: rule_parts[2], step: 1 } }
        ],
      ]
      expect(valid_walks).to include(rule.all_traveled_tiles(@game, { x: 3, y: 0, orientation: 1 }, { x: 4, y: 1 }))
    end
  end

  describe "find_compound_steps" do
    it "should be able to show all the transitory tiles used in a compound rule" do
      rule = GameRule.new({ direction: [ { direction: :forward,  steps: 2, collisions: :disabled }, { direction: :right,  steps: 1 } ], steps: 1 })
      expected_results = [ { x: 3, y: 2, orientation: 1 }, { x: 4, y: 2, orientation: 1 } ]
      expect(rule.find_compound_steps(@game, { x: 3, y: 0, orientation: 1 }, { x: 4, y: 2 })).to match(expected_results)
    end
    it "should be able to show all the transitory tiles used in a weird compound rule" do
      rule = GameRule.new({ direction: [ { direction: :forward, steps: { min: 1, max: 3 }, collisions: :disabled }, { direction: :right,  steps: { min: 1, max: 2 } }, { direction: :backward, steps: 1 }  ], steps: 1 })
      expected_results = [ { x: 3, y: 3, orientation: 1 }, { x: 4, y: 3, orientation: 1 }, { x: 4, y: 2, orientation: 1 } ]
      expect(rule.find_compound_steps(@game, { x: 3, y: 0, orientation: 1 }, { x: 4, y: 2 })).to match(expected_results)
    end
    it "should not return any compound steps ([]) when there are no valid paths between the two points" do
      rule = GameRule.new({ direction: [ { direction: :forward,  steps: 2, collisions: :none }, { direction: :right,  steps: 1 } ], steps: 1 })
      expected_results = [ ]
      expect(rule.find_compound_steps(@game_with_collisions, { x: 3, y: 0, orientation: 1 }, { x: 4, y: 2 })).to match(expected_results)
    end
  end

  describe "results_of_move between two points" do
    it "should give the results of each tile traveled for a simple rule" do
      rule = GameRule.new({ direction: :forward })
      expected_results = [
        { tile: { x: 3, y: 1, orientation: 1, rule_properties: { rule: rule, step: 0 } }, piece: {"id"=>"11", "name"=>"pawn", "orientation"=>-1 } },
        { tile: { x: 3, y: 2, orientation: 1, rule_properties: { rule: rule, step: 1 } }, piece: {"id"=> "8", "name"=>"pawn", "orientation"=>-1 } },
        { tile: { x: 3, y: 3, orientation: 1, rule_properties: { rule: rule, step: 2 } }, piece: :none },
        { tile: { x: 3, y: 4, orientation: 1, rule_properties: { rule: rule, step: 3 } }, piece: {"id"=> "2", "name"=>"pawn", "orientation"=>-1 } },
        { tile: { x: 3, y: 5, orientation: 1, rule_properties: { rule: rule, step: 4 } }, piece: {"id"=> "5", "name"=>"pawn", "orientation"=>-1 } },
        { tile: { x: 3, y: 6, orientation: 1, rule_properties: { rule: rule, step: 5 } }, piece: :none },
        { tile: { x: 3, y: 7, orientation: 1, rule_properties: { rule: rule, step: 6 } }, piece: :none }
      ]
      expect(rule.results_of_move(on: @game_with_collisions, from: { x: 3, y: 0, orientation: 1 }, to: { x: 3, y: 7 })).to match(expected_results)
    end
    it "should give the results of each tile traveled for a compound rule" do
      rule_parts = [
        GameRule.new({ direction: :forward,  steps: 2, collisions: :disabled }),
        GameRule.new({ direction: :right,    steps: 1 })
      ]
      rule = GameRule.new({ direction: rule_parts, steps: 1 })
      expected_results = [
        { tile: { x: 3, y: 1, orientation: 1, rule_properties: { rule: rule_parts[0], step: 0 } }, piece: {"id"=>"11", "name"=>"pawn", "orientation"=>-1 } },
        { tile: { x: 3, y: 2, orientation: 1, rule_properties: { rule: rule_parts[0], step: 1 } }, piece: {"id"=> "8", "name"=>"pawn", "orientation"=>-1 } },
        { tile: { x: 4, y: 2, orientation: 1, rule_properties: { rule: rule_parts[1], step: 0 } }, piece: {"id"=> "9", "name"=>"pawn", "orientation"=>-1 } },
      ]
      expect(rule.results_of_move(on: @game_with_collisions, from: { x: 3, y: 0, orientation: 1 }, to: { x: 4, y: 2 })).to match(expected_results)      
    end
  end

  describe "collisions" do
    before(:all) do
      @starting_point = { x: 3, y: 0, orientation: 1 }
    end
    it "should return the collisions for a valid move on a simple blocking rule" do
      game = Fabricate.build(:game)
      game.add_piece({ name: "pawn", x: 3, y: 5, orientation: -1 })
      rule = GameRule.new({ direction: :forward })
      expected_results = [
        { tile: { x: 3, y: 5, orientation: 1, rule_properties: { rule: rule, step: 4 } }, piece: {"id"=> "0", "name"=>"pawn", "orientation"=>-1 } }
      ]
      expect(rule.collisions(on: game, from: @starting_point, to: { x: 3, y: 5 })).to match(expected_results)
    end
    it "should return :invalid_collisions when blocking rules go too far" do
      game = Fabricate.build(:game)
      game.add_piece({ name: "pawn", x: 3, y: 5, orientation: -1 })
      rule = GameRule.new({ direction: :forward })
      expect(rule.collisions(on: game, from: @starting_point, to: { x: 3, y: 6 })).to eq(:invalid_collisions)
    end
    it "should return :invalid_collisions when colliding with your own pieces" do
      game = Fabricate.build(:game)
      game.add_piece({ name: "pawn", x: 3, y: 5, orientation: 1 })
      rule = GameRule.new({ direction: :forward })
      expect(rule.collisions(on: game, from: @starting_point, to: { x: 3, y: 5 })).to eq(:invalid_collisions)
    end
    it "should return :invalid_move when a rule violates step restraits" do
      rule = GameRule.new( { direction: :forward, steps: 2 })
      expect(rule.collisions(on: @game_with_collisions, from: @starting_point, to: { x: 3, y: 4 })).to eq(:invalid_move)
    end
    it "should return all collisions for rules that allow :all" do
      rule = GameRule.new( { direction: :forward, collisions: :all })
      expected_results = [
        { tile: { x: 3, y: 1, orientation: 1, rule_properties: { rule: rule, step: 0 } }, piece: {"id"=>"11", "name"=>"pawn", "orientation"=>-1 } },
        { tile: { x: 3, y: 2, orientation: 1, rule_properties: { rule: rule, step: 1 } }, piece: {"id"=> "8", "name"=>"pawn", "orientation"=>-1 } },
        { tile: { x: 3, y: 4, orientation: 1, rule_properties: { rule: rule, step: 3 } }, piece: {"id"=> "2", "name"=>"pawn", "orientation"=>-1 } },
        { tile: { x: 3, y: 5, orientation: 1, rule_properties: { rule: rule, step: 4 } }, piece: {"id"=> "5", "name"=>"pawn", "orientation"=>-1 } },
      ]
      expect(rule.collisions(on: @game_with_collisions, from: @starting_point, to: { x: 3, y: 7 })).to eq(expected_results)
    end
    it "should return jumping collisions" do
      rule = GameRule.new( { direction: :forward, collisions: :jumping })
      expected_results = [
        { tile: { x: 3, y: 2, orientation: 1, rule_properties: { rule: rule, step: 1 } }, piece: {"id"=> "8", "name"=>"pawn", "orientation"=>-1 } },
      ]
      expect(rule.collisions(on: @game_with_collisions, from: @starting_point, to: { x: 3, y: 2 })).to eq(expected_results)
      expect(rule.collisions(on: @game_with_collisions, from: { x: 3, y: 1, orientation: 1 }, to: { x: 3, y: 3 })).to eq([])
    end
    it "should return invalid_collisions when :none specified" do
      rule = GameRule.new( { direction: :forward, collisions: :none })
      expect(rule.collisions(on: @game_with_collisions, from: @starting_point, to: { x: 3, y: 2 })).to eq(:invalid_collisions)
    end
    it "should return [] when no collisions" do
      rule = GameRule.new({ direction: :forward })
      expect(rule.collisions(on: @game, from: @starting_point, to: { x: 3, y: 7 })).to eq([])
    end
    it "should return [] when collisions are :disabled" do
      rule = GameRule.new({ direction: :forward, collisions: :disabled })
      expect(rule.collisions(on: @game_with_collisions, from: @starting_point, to: { x: 3, y: 7 })).to eq([])
    end
    describe "on compound direction rules" do
      it "should return a basic knight collision" do
        rule_parts = [
          GameRule.new({ direction: :forward,  steps: 2, collisions: :disabled }),
          GameRule.new({ direction: :right, steps: 1 })
        ]
        rule = GameRule.new({ direction: rule_parts, steps: 1 })
        expected_results = [
          { tile: { x: 4, y: 2, orientation: 1, rule_properties: { rule: rule_parts[1], step: 0 } }, piece: {"id"=>"9", "name"=>"pawn", "orientation"=>-1 } }
        ]
        expect(rule.collisions(on: @game_with_collisions, from: @starting_point, to: { x: 4, y: 2 })).to eq(expected_results)
      end
      it "should return a weird boomerang collision set" do
        rule_parts = [
          GameRule.new({ direction: :forward,  collisions: :all }),
          GameRule.new({ direction: :right,    collisions: :all }),
          GameRule.new({ direction: :backward, collisions: :all })
        ]
        rule = GameRule.new({ direction: rule_parts, steps: 1 })
        expected_results = [
          { tile: { x: 2, y: 1, orientation: 1, rule_properties: { rule: rule_parts[0], step: 0 } }, piece: {"id"=>"10", "name"=>"pawn", "orientation"=>-1 } },
          { tile: { x: 2, y: 2, orientation: 1, rule_properties: { rule: rule_parts[0], step: 1 } }, piece: {"id"=> "7", "name"=>"pawn", "orientation"=>-1 } },
          { tile: { x: 2, y: 3, orientation: 1, rule_properties: { rule: rule_parts[0], step: 2 } }, piece: {"id"=>"13", "name"=>"pawn", "orientation"=>-1 } },
          { tile: { x: 2, y: 4, orientation: 1, rule_properties: { rule: rule_parts[0], step: 3 } }, piece: {"id"=> "1", "name"=>"pawn", "orientation"=>-1 } },
          { tile: { x: 2, y: 5, orientation: 1, rule_properties: { rule: rule_parts[0], step: 4 } }, piece: {"id"=> "4", "name"=>"pawn", "orientation"=>-1 } },
          { tile: { x: 3, y: 5, orientation: 1, rule_properties: { rule: rule_parts[1], step: 0 } }, piece: {"id"=> "5", "name"=>"pawn", "orientation"=>-1 } },
          { tile: { x: 4, y: 5, orientation: 1, rule_properties: { rule: rule_parts[1], step: 1 } }, piece: {"id"=> "6", "name"=>"pawn", "orientation"=>-1 } },
          { tile: { x: 4, y: 4, orientation: 1, rule_properties: { rule: rule_parts[2], step: 0 } }, piece: {"id"=> "3", "name"=>"pawn", "orientation"=>-1 } }
        ]
        expect(rule.collisions(on: @game_with_collisions, from: { x: 2, y: 0, orientation: 1 }, to: { x: 4, y: 4 })).to eq(expected_results)
      end
      it "should fail if any segment fails" do
        rule_parts = [
          GameRule.new({ direction: :forward, steps: 2 }),
          GameRule.new({ direction: :right,   steps: 1 })
        ]
        rule = GameRule.new({ direction: rule_parts, steps: 1 })
        expect(rule.collisions(on: @game_with_collisions, from: @starting_point, to: { x: 4, y: 2 })).to eq(:invalid_move)
      end
    end
  end
end
