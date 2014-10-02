/** @jsx React.DOM *//** @jsx React.DOM */

var MESS_PIECE_MAP = {
  pawn:   { "1": '\u2659', "-1": '\u265F' },
  knight: { "1": '\u2658', "-1": '\u265E' },
  bishop: { "1": '\u2657', "-1": '\u265D' },
  rook:   { "1": '\u2656', "-1": '\u265C' },
  queen:  { "1": '\u2655', "-1": '\u265B' },
  king:   { "1": '\u2654', "-1": '\u265A' },
  none:   { "1": ''       , "-1": ''        }
};

var NO_PIECE = { name: 'none', orientation: '1' };

var MessPiece = React.createClass({displayName: 'MessPiece',
  propTypes: {
    piece: React.PropTypes.object.isRequired,
    onMoveOptionsRequested: React.PropTypes.func
  },
  showOptions: function(event) {
    console.debug("Showing Options for: %o", this.props.piece);
    // pass up to function showMoveOptionsFor(pieceId)
  },
  getPieceIcons: function(type) { return MESS_PIECE_MAP[type] || MESS_PIECE_MAP.none },
  render: function() {
    var gamePieceIcon = this.getPieceIcons(this.props.piece.name)[this.props.piece.orientation];
    return(<div className="small-1 columns game-piece" onMouseDown={this.showOptions}>{gamePieceIcon}</div>);
  }
});

var BoardRow = React.createClass({displayName: 'BoardRow',
  propTypes: {
    rowId: React.PropTypes.number.isRequired,
    pieces: React.PropTypes.object.isRequired,
    board: React.PropTypes.object.isRequired
  },
  pieceOnTile: function(row, column) {
    return(this.props.board[column + ',' + row] || 'none');
  },
  getPiece: function(column) {
    return(this.props.pieces[this.pieceOnTile(this.props.rowId, column)] || NO_PIECE);
  },
  render: function() {
    var columns = [];
    for(var column=0; column<8; column++) { columns.push(<MessPiece key={column} piece={this.getPiece(column)} />); }
    return(
      <div className="row">
        {columns}
        <div className="small-4 columns"></div>
      </div>
      
    );
  }
});

var MessGame = React.createClass({ displayName: 'MessGame',
  propTypes: {
    pieces: React.PropTypes.object.isRequired,
    board: React.PropTypes.object.isRequired
  },
  render: function() {
    var rows = [];
    console.debug("Board: %o", this.props.board);
    for(var row=7; row>=0; row--) { rows.push(<BoardRow key={row} rowId={row} pieces={this.props.pieces} board={this.props.board} />); }
    return(
      <div className="chess-board">
        {rows}
      </div>
    );
  }
});

// React.renderComponent(<MessGame />, document.querySelector('.react-mess-board'));