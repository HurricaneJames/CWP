class Game < ActiveRecord::Base
  serialize :current_state, ApplicationHelper::JSONWithIndifferentAccess

  validate :current_state_must_include_board_and_pieces

  def board; current_state[:board]; end
  def board=(board); current_state[:board] = board; end
  def pieces; current_state[:pieces]; end
  def pieces=(pieces); current_state[:pieces] = pieces; end
  def current_state=(new_state); self[:current_state] = JSON.parse(new_state).with_indifferent_access; end
  def game_rules; @game_rules ||= GameRules.new; end

  def move(move_string)
    raise ArgumentError.new, "invlaid move." if move_string.blank?
    move_positions = move_string.present? ? move_string.split(':') : []
    raise ArgumentError.new, "invalid move." if move_positions.nil? || move_positions[0].blank? || move_positions[1].blank?
    piece_id = id_piece_on_tile(move_positions[0])
    return false unless is_legal?(piece_id: piece_id, to: position_for(tile_id: move_positions[1]))
    #
    # do any conflict resolution here (probabilities at some point)
    #
    board[move_positions[1]] = board.delete(move_positions[0])
    self.moves = moves.to_s + move_string + ';'
    return true
  end

  # todo - DRY up these two move methods
  def move_piece(from:, to:)
    raise ArgumentError.new, "invlid move parameters" if (from.blank? || to.blank?)
    piece_id = id_piece_on_tile(from)
    return false unless is_legal?(piece_id: piece_id, to: to)
    from_id = tile_id_for(from[:x], from[:y])
    to_id   = tile_id_for(to[:x],   to[:y])
    #
    # do any conflict resolution here (probabilities at some point)
    #
    board[to_id] = board.delete(from_id)
    self.moves = moves.to_s + "#{from[:x]},#{from[:y]}:#{to[:x]},#{to[:y]}" + ';'
    return true
  end

  def collision_resolution(piece_id, to)
    dead_pieces = get_attack_result(piece_id, to)
    # remove dead pieces from board
    # return whether this was a successful assult
    raise "not fully implemented"
  end

  def get_attack_result(piece_id, to)
    dead_pieces = []
    rule = game_rules.legal_rule_for(game: self, move: { id: piece_id, to: to })
    collisions = rule.get_collisions(from, to)
    collisions.each do |collision|
      if attacker_wins_position?(collision)
        dead_pieces << piece_on_tile(collision)
      else
        dead_pieces << piece[piece_id]
        break
      end
    end
    return dead_pieces
  end

  def attacker_wins_position?(collision)
    # todo - add hit points resolve_collision(game:, attacker:, defender:)
    Random.rand < collision[:probability_result]
  end


  def is_legal?(piece_id:, to:)
    game_rules.is_move_legal?(game: self, move: { id: piece_id, to: to })
  end

  def all_legal_moves_for_piece(id)
    game_rules.all_moves_for_piece(game: self, piece_id: id)
  end

  # position: { x: [x], y: [y] }
  def on_board?(position)
    position[:x] >= 0 && position[:x] <= 7 && position[:y] >= 0 && position[:y] <= 7
  end

  # return the piece on the given tile
  # or :none, :off_board
  def piece_on_tile(tile)
    raise ArgumentError.new, "(#{tile}) is an invalid tile." if tile.blank? || tile[:x].nil? || tile[:y].nil?
    return :off_board unless on_board?(tile)
    piece_id = id_piece_on_tile(tile)
    pieces[piece_id].present? ? pieces[piece_id].merge({ id: piece_id }) : :none
  end

  def id_piece_on_tile(tile)
    tile_id = tile.is_a?(String) ? tile : tile_id_for(tile[:x], tile[:y])
    return board[tile_id].to_s
  end

  def add_piece(name:, x:, y:, orientation: 1)
    new_id = pieces.length.to_s
    pieces[new_id] = { id: new_id, name: name, orientation: orientation }
    board[tile_id_for(x, y)] = new_id
  end

  def remove_piece(x:, y:)
    pieces[board.delete(tile_id_for(x, y)).to_s]
  end

  def get_tile_for_piece(id)
    tile_string = board.detect { |tile, piece_id_on_tile| piece_id_on_tile == id }
    return nil if tile_string.blank?
    tile = tile_string.first.split(',')
    return { x: tile[0].to_i, y: tile[1].to_i, orientation: pieces[id][:orientation] }
  end

  private
    def parse_move_string(move_string)
      move_array = move_string.split(':')
      {
        from: position_for(tile_id: move_array[0]),
        to:   position_for(tile_id: move_array[1])
      }
    end

    def tile_id_for(x, y); "#{x},#{y}"; end
    def position_for(tile_id:); puts "Getting Tile For #{tile_id}"; [:x, :y].zip(tile_id.split(',').map { |o| o.to_i }).to_h; end

    def current_state_must_include_board_and_pieces
      errors.add(:current_state, "must include the board") if board.nil?
      errors.add(:current_state, "must include pieces") if pieces.nil?
    end

    def translate_move(piece_id, to)
      # todo - add piece[:on_board] attribute to skip the check if this piece is currently dead/off-board
      piece_id = piece_id.to_s
      from = get_tile_for_piece(piece_id)
      { name: pieces[piece_id][:name], from: from, to: to }
    end
end
