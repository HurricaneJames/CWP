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
    piece:  React.PropTypes.object.isRequired,
    row:    React.PropTypes.number.isRequired,
    column: React.PropTypes.number.isRequired,
    activePiece:      React.PropTypes.string,
    moveOptionsCache: React.PropTypes.object.isRequired,
    onMouseDownOnPiece: React.PropTypes.func,
    onClickOnPiece:     React.PropTypes.func,
  },
  onMouseDown: function(event) { if(this.props.onMouseDownOnPiece && this.props.piece.name != 'none') this.props.onMouseDownOnPiece(this.props.piece.id, event); },
  onClick:     function(event) { if(this.props.onClickOnPiece     && this.props.piece.name != 'none') this.props.onClickOnPiece(this.props.piece.id, event); },
  getPieceIcons: function(type) { return MESS_PIECE_MAP[type] || MESS_PIECE_MAP.none },
  shouldHighlight: function() {
    var moveOptions = this.props.moveOptionsCache[this.props.activePiece]
    if(!moveOptions) return false;
    for(var i=0, len=moveOptions.length; i<len; i++) {
      if (moveOptions[i].x == this.props.column && moveOptions[i].y == this.props.row) { return true;}
    }
    return false;
  },
  render: function() {
    var gamePieceIcon = this.getPieceIcons(this.props.piece.name)[this.props.piece.orientation]
      , elementClass  = "small-1 columns game-piece" + (this.shouldHighlight() ? ' possible-tile' : '');
    return(<div className={elementClass} onMouseDown={this.onMouseDown} onClick={this.onClick}>{gamePieceIcon}</div>);
  }
});

var BoardRow = React.createClass({displayName: 'BoardRow',
  propTypes: {
    rowId:  React.PropTypes.number.isRequired,
    pieces: React.PropTypes.object.isRequired,
    board:  React.PropTypes.object.isRequired,
    activePiece:      React.PropTypes.string,
    moveOptionsCache: React.PropTypes.object.isRequired,
    onMouseDownOnPiece: React.PropTypes.func,
    onClickOnPiece:     React.PropTypes.func,
  },
  pieceOnTile: function(row, column) {
    return(this.props.board[column + ',' + row] || 'none');
  },
  getPiece: function(column) {
    return(this.props.pieces[this.pieceOnTile(this.props.rowId, column)] || NO_PIECE);
  },
  render: function() {
    var columns = [];
    for(var column=0; column<8; column++) {
      columns.push(<MessPiece key={column}
                              row={this.props.rowId} column={column}
                              piece={this.getPiece(column)}
                              activePiece={this.props.activePiece}
                              moveOptionsCache={this.props.moveOptionsCache}
                              onMouseDownOnPiece={this.props.onMouseDownOnPiece}
                              onClickOnPiece={this.props.onClickOnPiece} />);
    }
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
    board: React.PropTypes.object.isRequired,
    gameId: React.PropTypes.number.isRequired,
  },
  getInitialState: function() {
    return { moveOptionsCache: {}, activePiece: undefined };
  },
  getMoveOptions: function(pieceId, callback) {
    var _this = this;
    if(this.state.moveOptionsCache[pieceId]) { if(callback) callback(this.state.moveOptionsCache[pieceId]); }
    else {
      console.debug("Move Options Not in Cache. Fetching from server...");
      $.ajax({
        url: "/api/v1/games/" + this.props.gameId + "/available_moves/" + pieceId,
        dataType: 'json'
      })
      .done(function(data, status, jqXHR)  { _this.state.moveOptionsCache[pieceId] = data; _this.setState(_this.state); if(callback) callback(data); })
      .fail(function(jqXHR, status, error) { console.debug("Failure: %o", error); });
    }
  },
  onMouseDownOnPiece: function(pieceId) {
    console.debug("Move Options Requested for: %o", pieceId);
    this.getMoveOptions(pieceId);
  },
  onClickOnPiece: function(pieceId) {
    console.debug("Click: %o", pieceId);
    this.state.activePiece = this.state.activePiece == pieceId ? undefined : pieceId;
    this.setState(this.state);
  },
  render: function() {
    var rows = [];
    for(var row=7; row>=0; row--) {
      rows.push(<BoardRow key={row}
                          rowId={row}
                          pieces={this.props.pieces}
                          board={this.props.board}
                          activePiece={this.state.activePiece}
                          moveOptionsCache={this.state.moveOptionsCache}
                          onMouseDownOnPiece={this.onMouseDownOnPiece}
                          onClickOnPiece={this.onClickOnPiece} />);
    }
    return(
      <div className="chess-board">
        {rows}
      </div>
    );
  }
});

// React.renderComponent(<MessGame />, document.querySelector('.react-mess-board'));