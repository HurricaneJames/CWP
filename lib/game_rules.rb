class GameRules
  # TODO - remove this method
  def debug_get_rules; @game_rules; end

  # One of the goals for CWP is to make the engine expandable to different types of games, otherwise A/B testing of
  # different probabilities/move sets would be impossible. Therefore, hardcoding the logic isn't really possible.
  # Maybe, at some point, a system can be created where a game type is come from coded ruby code (fast) or from the
  # DB. Until then, pulling from the DB is the best choice. The next step would be to use memcached to cache the
  # expanded ruleset locally, for scalling purposes.

  # All that said, for iteration_1, the default game rules are hardcoded here. They are also written in a
  # "simplified syntax" that should make it easier to read/modify.

  # Note: Iteration 1 has no "special" rules (2 steps option on first move for pawns, pawn promotion, king/rook castling, pawn en passant)

  def initialize
    @game_rules = get_default_game_rules.with_indifferent_access
  end

  def add_rule(piece_type, rule)
    @game_rules[piece_type] ||= []
    @game_rules[piece_type] << rule unless @game_rules[piece_type].include? rule
  end

  # checks if this is technically a possible move (even if it might not happen due to probabilities going the wrong way)
  # could also check if this is a legal move based on the move containing encoded probabilities (board validation post-game)
  # Move Syntax
  #   { "piece": "[id]", "to": "[x], [y]" }
  def is_move_legal?(game:, move:)
    # return false if game.blank? || move.blank?
    # full_move = translate_move(game, move)
    # @game_rules[full_move[:name]].each { |rule| return true if rule.is_valid?(on: game, from: full_move[:from], to: full_move[:to]) }
    # return false
    return legal_rule_for(game: game, move: move).present?
  end

  def all_moves_for_piece(game:, piece_id:, include_probabilities: false)
    # todo - fix this so it does not have to pull so much information from the game (replace: piece_id with piece: { x:, y:, name: })
    move_set = Set.new
    id = piece_id.to_s
    rule_type = game.pieces[id][:name]
    @game_rules[rule_type].each { |rule| move_set.merge(rule.all_valid_moves(on: game, from_positions: game.get_tile_for_piece(id), include_probabilities: include_probabilities)) }
    return move_set
  end

  def legal_rule_for(game:, move:)
    return nil if game.blank? || move.blank?
    full_move = translate_move(game, move)
    # @game_rules[full_move[:name]].each { |rule| return rule if rule.is_valid?(on: game, from: full_move[:from], to: full_move[:to]) }
    return @game_rules[full_move[:name]].detect { |rule| rule.is_valid?(on: game, from: full_move[:from], to: full_move[:to]) }
  end

  def promotions_for_move(move_params)
    promotion_rules = @game_rules[:promotion_rules][move_params[:type]] || []
    promotion_rules.select { |promotion_rule| promotion_conditions_met?(promotion_rule[:conditions], move_params) }.collect { |promotion_rule| promotion_rule[:options] }.flatten.uniq
  end

  def can_promote?(piece, to, new_type)
    return false unless valid_type?(new_type)
    promotion_possibilities = promotions_for_move({ type: piece[:name], to: to })
    return promotion_possibilities.include? new_type.to_sym
  end

  def valid_type?(piece_type)
    @game_rules[piece_type].present?
  end

  private

    def promotion_conditions_met?(condition_params, move_params)
      condition_params.each do |test_on, value|
        case test_on
        when "to"
          return false if value["y"].present? && move_params[:to][:y] != value[:y]
          return false if value["x"].present? && move_params[:to][:x] != value[:x]
        else
          # undefined rule
          return false
        end
      end
      return true
    end

    # guarantees that move is in correct format
    def translate_move(game, move)
      new_move = move.is_a?(String) ? parse_move(move) : move.dup
      piece_id = new_move[:id].to_s
      piece = game.pieces[piece_id]
      new_move[:name]        = piece[:name] unless new_move[:name].present?
      new_move[:from]        = game.get_tile_for_piece(piece_id) unless new_move[:from].present?
      return new_move
    end

    def parse_move(move_string)
      parts = move_string.split(':')
      tile = parts[1].split(',')
      { id: parts[0].to_i, to: { x: tile[0].to_i, y: tile[1].to_i } }
    end

    def get_default_game_rules
      default_game_rules = default_game_rules_with_simplified_syntax
      promotion_rules = default_game_rules.delete :promotion_rules
      default_game_rules.each_with_object({promotion_rules: promotion_rules}) { |(piece_type, piece_rules), o| o[piece_type] = piece_rules.map { |rule| GameRule.new(rule) } }
    end

    def map_rule_specs_to_objects(specs)
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
                  { direction: [ { direction: :left,  steps: 2, collisions: :disabled }, { direction: :forward,  steps: 1 } ], steps: 1 },
                  { direction: [ { direction: :left,  steps: 2, collisions: :disabled }, { direction: :backward, steps: 1 } ], steps: 1 },
                  { direction: [ { direction: :right, steps: 2, collisions: :disabled }, { direction: :forward,  steps: 1 } ], steps: 1 },
                  { direction: [ { direction: :right, steps: 2, collisions: :disabled }, { direction: :backward, steps: 1 } ], steps: 1 },
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
                  { direction: :diagonal_backward_left, steps: 1 }, { direction: :diagonal_backward_right, steps: 1 } ],
        promotion_rules: {
          pawn: [
            { conditions: { to: { y: 7 } }, options: [:rook, :knight, :bishop, :queen ] },
            { conditions: { to: { y: 0 } }, options: [:rook, :knight, :bishop, :queen ] }
          ]
        }
      }
    end
end