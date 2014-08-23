class Game < ActiveRecord::Base
  serialize :current_state, JSON

  validate :current_state_must_include_board_and_pieces

  def initialize(args = {})
    super
    self.current_state ||= '{"pieces": {}, "board": {}}'
    # self.pieces ||= {}
    # self.board  ||= {}
  end

  def board; current_state[:board]; end
  def board=(board); current_state[:board] = board; end
  def pieces; current_state[:pieces]; end
  def pieces=(pieces); current_state[:pieces] = pieces; end

  def current_state=(new_state)
    self[:current_state] = JSON.parse(new_state).with_indifferent_access
  end

  def game_rules; @game_rules ||= GameRules.new; end

  def is_legal?(piece_id:, to:)
    # move = translate_move(piece_id, to)
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
    raise ArgumentError.new, "invalid tile." if tile.blank? || tile[:x].blank? || tile[:y].blank?
    return :off_board unless on_board?(tile)
    tile_id = tile_id_for(tile[:x], tile[:y])
    piece_id = board[tile_id].to_s
    pieces[piece_id].present? ? pieces[piece_id] : :none
  end

  def add_piece(name:, x:, y:, orientation: 1)
    new_id = pieces.length.to_s
    pieces[new_id] = { name: name, orientation: orientation }
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
    def tile_id_for(x, y); "#{x},#{y}"; end

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
