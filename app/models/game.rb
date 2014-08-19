class Game < ActiveRecord::Base
  serialize :current_state, JSON

  validate :current_state_must_include_board_and_pieces

  def board; current_state[:board]; end
  def pieces; current_state[:pieces]; end

  def current_state=(new_state)
    self[:current_state] = JSON.parse(new_state).with_indifferent_access
  end

  def game_rules; @game_rules ||= GameRules.new(:default); end

  # position: { x: [x], y: [y] }
  def on_board?(position)
    position[:x] >= 0 && position[:x] <= 8 && position[:y] >= 0 && position[:y] <= 8
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

  def add_piece(name:, x:, y:)
    new_id = pieces.length.to_s
    pieces[new_id] = { name: name }
    board[tile_id_for(x, y)] = new_id
  end

  private
    def tile_id_for(x, y); "#{x},#{y}"; end

    def current_state_must_include_board_and_pieces
      errors.add(:current_state, "must include the board") if board.nil?
      errors.add(:current_state, "must include pieces") if pieces.nil?
    end
end
