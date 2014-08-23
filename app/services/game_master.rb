class GameMaster
  def self.new_game
    standard_chess_layout
  end

  def self.standard_chess_layout
    game = Game.new
    (0..7).each do |x|
      game.add_piece(name: "pawn", x: x, y: 1, orientation:  1)
      game.add_piece(name: "pawn", x: x, y: 6, orientation: -1)
    end
    game.add_piece(name: 'rook', x: 0, y: 0, orientation:  1)
    game.add_piece(name: 'rook', x: 0, y: 7, orientation:  1)
    game.add_piece(name: 'rook', x: 7, y: 0, orientation: -1)
    game.add_piece(name: 'rook', x: 7, y: 7, orientation: -1)

    game.add_piece(name: 'knight', x: 0, y: 1, orientation:  1)
    game.add_piece(name: 'knight', x: 0, y: 6, orientation:  1)
    game.add_piece(name: 'knight', x: 7, y: 1, orientation: -1)
    game.add_piece(name: 'knight', x: 7, y: 6, orientation: -1)

    game.add_piece(name: 'bishop', x: 0, y: 2, orientation:  1)
    game.add_piece(name: 'bishop', x: 0, y: 5, orientation:  1)
    game.add_piece(name: 'bishop', x: 7, y: 2, orientation: -1)
    game.add_piece(name: 'bishop', x: 7, y: 5, orientation: -1)

    game.add_piece(name: 'queen', x: 0, y: 3, orientation:  1)
    game.add_piece(name: 'queen', x: 0, y: 4, orientation: -1)

    game.add_piece(name: 'king', x: 0, y: 4, orientation:  1)
    game.add_piece(name: 'king', x: 0, y: 3, orientation: -1)

    return game
  end
end