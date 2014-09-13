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
    raise ArgumentError.new, "Move cannot be empty." if move_string.blank?
    move_positions = move_string.present? ? move_string.split(':') : []
    raise ArgumentError.new, "Did not describe move or used an invalid syntax." if move_positions.nil? || move_positions[0].blank? || move_positions[1].blank?
    from = [:x, :y].zip(move_positions[0].split(',').map {|i| i.to_i}).to_h
    to   = [:x, :y].zip(move_positions[1].split(',').map {|i| i.to_i}).to_h
    return move_piece(from: from, to: to)
  end

  # todo - DRY up these two move methods
  def move_piece(from:, to:)
    raise ArgumentError.new, "invlid move parameters" if (from.blank? || to.blank?)
    piece_id = id_piece_on_tile(from)
    return false unless is_legal?(piece_id: piece_id, to: to)
    dead_pieces = handle_collisions_of_attack(piece_id, to)
    dead_piece_ids = dead_pieces.split(',')
    change_board_position(piece_id, from, to) unless dead_piece_ids.include?(piece_id)
    self.moves = moves.to_s + "#{from[:x]},#{from[:y]}:#{to[:x]},#{to[:y]}" +
      ":#{dead_pieces}" +
      win_lose_or_normal(dead_piece_ids, pieces[piece_id][:orientation]) +
      ';'
    return true
  end

  def win_lose_or_normal(dead_piece_ids, attacking_piece_id)
    dead_kings = dead_piece_ids.select { |piece_id| pieces[piece_id][:name] == "king" }
    return "draw" if dead_kings.length > 1
    dead_king = dead_kings.first
    return (pieces[dead_king][:orientation] == attacking_piece_id ? ":lost" : ":won") if dead_kings.length == 1
    return ''
  end

  def change_board_position(piece_id=nil, from = nil, to)
    raise ArgumentError.new, "either piece_id or from must be valid" if (piece_id.blank? && from.blank?)
    raise ArgumentError.new, "must specify destination tile" if to.blank?
    from ||= get_tile_for_piece(piece_id)
    piece_id ||= id_piece_on_tile(from)
    from_id = tile_id_for(from[:x], from[:y])
    to_id   = tile_id_for(to[:x],   to[:y])
    board[to_id] = board.delete(from_id)
    pieces[piece_id][:state] = to_id
  end

  def handle_collisions_of_attack(piece_id, to)
    dead_pieces = get_results_of_moving_piece(piece_id, to)
    collision_results = ""
    dead_pieces.each do |piece|
      kill_piece(piece[:id])
      collision_results << piece[:id] + ','
    end
    return collision_results[0...-1]
  end

  def kill_piece(piece_id)
    tile = get_tile_for_piece(piece_id)
    piece = remove_piece(x: tile[:x], y: tile[:y])
    piece[:state] = :dead
  end

  # returns the set of pieces that lost (dead pieces)
  def get_results_of_moving_piece(piece_id, to)
    dead_pieces = []
    rule = game_rules.legal_rule_for(game: self, move: "#{piece_id}:#{to[:x]},#{to[:y]}")
    collisions = rule.collisions(on: self, from: get_tile_for_piece(piece_id), to: to)
    collisions.each do |collision_at|
      if collision_at[:tile][:rule_properties][:rule].resolve_collision(collision_at)
        dead_pieces << piece_on_tile(collision_at[:tile])
      else
        dead_pieces << pieces[piece_id]
        break
      end
    end
    return dead_pieces
  end

  def winner
    move_set = moves.split(';')
    return (move_set.length.odd? ? 1 : -1) if move_marked_as_won?(move_set.last)
    return 0
  end

  def move_marked_as_won?(move)
    move.try(:split, ':').try(:last) == "won"
  end

  def is_legal?(piece_id:, to:)
    can_move_piece_this_turn(piece_id) && game_rules.is_move_legal?(game: self, move: { id: piece_id, to: to })
  end

  def can_move_piece_this_turn(piece_id)
    winner == 0 && (pieces[piece_id.to_s][:orientation] > 0 ? moves.split(';').length.even? : moves.split(';').length.odd?)
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
    pieces[new_id] = { id: new_id, name: name, orientation: orientation, state: "#{x},#{y}" }
    board[tile_id_for(x, y)] = new_id
  end

  def remove_piece(x:, y:)
    piece_id = board.delete(tile_id_for(x, y)).to_s
    pieces[piece_id][:state] = ''
    return pieces[piece_id]
  end

  def add_rule(piece_type, rule); game_rules.add_rule(piece_type, rule); end

  def get_tile_for_piece(id)
    tile_string = tile_id_for_piece(id)
    return nil if tile_string.blank?
    tile = tile_string.split(',')
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
    def position_for(tile_id:); [:x, :y].zip(tile_id.split(',').map { |o| o.to_i }).to_h; end
    # TODO - replace this with pieces[piece_id][:state] - because that is what state is supposed to represent
    def tile_id_for_piece(piece_id); board.detect { |tile, piece_id_on_tile| piece_id_on_tile == piece_id }.try(:first); end

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
