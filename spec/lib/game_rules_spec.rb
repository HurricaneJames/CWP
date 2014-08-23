require 'rails_helper'

RSpec.describe GameRule do
  describe "legal move syntax" do
    before(:all) do
      @game = Fabricate.build(:game)
      @game.add_piece(name: "pawn", x: 3, y: 3)
      @game_rules = GameRules.new
    end
    it "should accept {id, to}" do
      move = { id: 0, to: { x: 3, y: 4 } }
      expect(@game_rules.is_move_legal?(game: @game, move: move)).to be_truthy
    end

    it "should accept 'id:x,y' as {id, to}" do
      move = '0:3,4'
      expect(@game_rules.is_move_legal?(game: @game, move: move)).to be_truthy
    end

    pending "Describe alternative game rule syntax"
    # pending "should accept {name, from, to}"
    # pending "should accept 'name:x,y:x,y' as {id, from ,to}"
    # # note, this one is harder because it requires testing every piece with name to see which one can go to 'to'
    # pending "should eventually accept 'name:x:y' as {name, to}"
    # # this may be the hardest of all as it is the official chess algebra syntax and requires looking at every piece
    # # to see which can move to 'to'
    # pending "should eventually accept 'x,y' as {to}"
  end

  pending "Describe Game Rules (once they are finalized)"
  # pending "describe Pawn motion"
  # pending "describe Rook motion"
  # pending "describe Knight motion"
  # pending "describe Bishop motion"
  # pending "describe Queen motion"
  # pending "describe King motion"
end