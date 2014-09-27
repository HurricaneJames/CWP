module GamesHelper
  def piece_icons
    @icons ||= {
      "1" => {
        "pawn"   => "&#9817;",
        "knight" => "&#9816;",
        "bishop" => "&#9815;",
        "rook"   => "&#9814;",
        "queen"  => "&#9813;",
        "king"   => "&#9812;"
      },
      "-1" => {
        "pawn"   => "&#9823;",
        "knight" => "&#9822;",
        "bishop" => "&#9821;",
        "rook"   => "&#9820;",
        "queen"  => "&#9819;",
        "king"   => "&#9818;"
      }
    }
  end
  def piece_icon_for(piece_type, piece_orientation)
    # "#{piece_orientation > 0 ? "&#9650;".html_safe : "&#9660;" }".html_safe + "#{piece_type}"
    piece_icons[piece_orientation.to_s][piece_type.to_s].html_safe
  end
end
