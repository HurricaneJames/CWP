class Game < ActiveRecord::Base
  # Attributes: current_state, moves
  def legal_move?(move)
    # is move on board
    # is move in range of places piece is allowed to move
    # 
  end

  # return the piece on the given tile
  # or :none, :off_board
  def piece_on_tile(tile)
    raise "NOT YET IMPLEMENTED"
  end
end
