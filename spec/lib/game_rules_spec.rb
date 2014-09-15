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
      bad_move = { id: 0, to: { x: 3, y: 7 } }
      expect(@game_rules.is_move_legal?(game: @game, move: bad_move)).to be_falsey
    end

    it "should accept 'id:x,y' as {id, to}" do
      move = '0:3,4'
      expect(@game_rules.is_move_legal?(game: @game, move: move)).to be_truthy
      bad_move = '0:3,7'
      expect(@game_rules.is_move_legal?(game: @game, move: bad_move)).to be_falsey
    end

    pending "should get all legal moves for a piece" 

    it "should find the rule that moves a piece to a specific location" do
      # note: there is nothing in the syntax that prevents multiple rules from allowing the same space.
      #       however, there is a requirement that no two rules can put a piece on the same time.
      #       there is no guarantee as to which rule will be selected if that requirement is broken.
      move = '0:3,4'
      rule = @game_rules.legal_rule_for(game: @game, move: move)
      expect(rule).to be_present
      expect(rule).to be_instance_of(GameRule)
      expect(rule.is_valid?(on: @game, from: { x: 3, y: 3, orientation: 1 }, to: { x: 3, y: 4 })).to be_truthy
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
  it "should give valid promotion options for a pawn" do
    game_rules = GameRules.new
    expect(game_rules.promotions_for_move({ type: "pawn", to: { x: 3, y: 7 } })).to eq([:rook, :knight, :bishop, :queen])
  end
  # pending "describe Rook motion"
  # pending "describe Knight motion"
  # pending "describe Bishop motion"
  # pending "describe Queen motion"
  # pending "describe King motion"
end