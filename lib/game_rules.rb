class GameRules
  # One of the goals for CWP is to make the engine expandable to different types of games, otherwise A/B testing of
  # different probabilities/move sets would be impossible. Therefore, hardcoding the logic isn't really possible.
  # Maybe, at some point, a system can be created where a game type is come from coded ruby code (fast) or from the
  # DB. Until then, pulling from the DB is the best choice. The next step would be to use memcached to cache the
  # expanded ruleset locally, for scalling purposes.

  # All that said, for iteration_1, the default game rules are hardcoded here. They are also written in a
  # "simplified syntax" that should make it easier to read/modify.

  # Note: Iteration 1 has no "special" rules (2 steps option on first move for pawns, pawn promotion, king/rook castling, pawn en passant)

  def initialize(game_type=nil)
    # ignore game_type for now
    @game_rules = get_default_game_rules
  end

  # checks if this is technically a possible move (even if it might not happen due to probabilities going the wrong way)
  # could also check if this is a legal move based on the move containing encoded probabilities (board validation post-game)
  # Move Syntax
  #   { "piece": "[id]", "to": "[x], [y]" }
  def is_move_legal?(game, move)
    return false if game.blank? || move.blank?
    # get piece from move (decode move)
    piece = game.piece(move["piece"])
    # rules[:piece].each { |rule| return true if is_tile_reachable?(rule, start_pos, end_pos_from_(move)) }
    @game_rules[piece.rule_type].each do |piece_rule|
      return true if       
    end
    # return false
  end

  private
  def get_default_game_rules
    expand_move_syntax_from! default_game_rules_with_simplified_syntax
  end

  def default_game_rules_with_simplified_syntax
    @piece_normal_move_hash ||= {
      pawn:   [ { direction: :forward, steps: 1, result: :weak }, { direction: :diagonal_forward_left, steps: 1 }, { direction: :diagonal_forward_right, steps: 1 } ],
      rook:   [ { direction: :forward }, { direction: :backward }, { direction: :left }, { direction: :right },
                { direction: :diagonal_forward_left,  steps: 1, result: :weak }, { direction: :diagonal_forward_right,  steps: 1, result: :weak },
                { direction: :diagonal_backward_left, steps: 1, result: :weak }, { direction: :diagonal_backward_right, steps: 1, result: :weak } ],
      knight: [ { direction: [ { direction: :forward,  steps: 2, collisions: :disabled }, { direction: :left,  steps: 1 } ], steps: 1 },
                { direction: [ { direction: :forward,  steps: 2, collisions: :disabled }, { direction: :right, steps: 1 } ], steps: 1 },
                { direction: [ { direction: :backward, steps: 2, collisions: :disabled }, { direction: :left,  steps: 1 } ], steps: 1 },
                { direction: [ { direction: :backward, steps: 2, collisions: :disabled }, { direction: :right, steps: 1 } ], steps: 1 },
                { direction: :diagonal_forward_left,   steps: 2, collisions: :all, result: [0.75, 0.25] },
                { direction: :diagonal_forward_right,  steps: 2, collisions: :all, result: [0.75, 0.25] },
                { direction: :diagonal_backward_left,  steps: 2, collisions: :all, result: [0.75, 0.25] },
                { direction: :diagonal_backward_right, steps: 2, collisions: :all, result: [0.75, 0.25] } ],
      bishop: [ { direction: :diagonal_forward_left },  { direction: :diagonal_forward_right },
                { direction: :diagonal_backward_left }, { direction: :diagonal_backward_right },
                { direction: :forward, steps: 1, result: :weak }, { direction: :backward, steps: 1, result: :weak },
                { direction: :left,    steps: 1, result: :weak }, { direction: :right,    steps: 1, result: :weak } ],
      queen:  [ { direction: :forward }, { direction: :backward }, { direction: :left }, { direction: :right },
                { direction: :diagonal_forward_left },  { direction: :diagonal_forward_right },
                { direction: :diagonal_backward_left }, { direction: :diagonal_backward_right } ],
      king:   [ { direction: :forward, steps: 1 }, { direction: :backward, steps: 1 }, { direction: :left, steps: 1 }, { direction: :right, steps: 1 },
                { direction: :diagonal_forward_left,  steps: 1 }, { direction: :diagonal_forward_right,  steps: 1 },
                { direction: :diagonal_backward_left, steps: 1 }, { direction: :diagonal_backward_right, steps: 1 } ]
    }
  end

  def result_probabilities
    @result_probabilities ||= { strong: [ 0.9 ], weak: [ 0.2 ] }
  end

  def expand_move_syntax_from!(rule_set)
    rule_set.each do |rule_element|
      expand_keywords_in! rule_element
    end
  end

  def expand_keywords_in!(rule_element)
    expand_result_keywords_in rule_element
    expand_move_syntax_from! rule_element if rule_element.is_a?(Enumerable)
  end

  def is_direction_element?(rule_element)
    rule_element.is_a?(Hash) && rule_element[:direction].present?
  end

  # expand :strong/:weak => [ 0.9 ] / [ 0.2 ]
  def expand_result_keywords_in(rule_element)
    rule_element[:result] = result_probabilities[rule_element[:result]] if is_direction_element?(rule_element) && rule_element[:result].present?
  end

  # expand default result ( [90%] )
  def add_default_result_probability_to(rule_element)
    rule_element[:result] = result_probabilities[:strong] if is_direction_element?(rule_element) && rule_element[:result].blank?
  end

end