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
    highlights: React.PropTypes.object,
    onMouseDownOnTile: React.PropTypes.func,
    onClickOnTile:     React.PropTypes.func,
  },
  getDefaultProps: function() {
    var blankFunction = function() {};
    return {
      onMouseDownOnTile: blankFunction,
      onClickOnTile:    blankFunction
    };
  },
  getPieceIcons: function(type) { return MESS_PIECE_MAP[type] || MESS_PIECE_MAP.none },
  getHighlightClasses: function(tileHighlights) {
    if(!tileHighlights) { return ""; }
console.debug("Setting Weak/Strong");
    if(tileHighlights.probability > 0.75) { return "attack-strong"; }
    else { return "attack-weak"; }

  },
  render: function() {
    var gamePieceIcon  = this.getPieceIcons(this.props.piece.name)[this.props.piece.orientation]
      , tileHighlights = this.props.highlights && this.props.highlights[this.props.row + ',' + this.props.column]
      , elementClass   = "small-1 columns game-piece " + this.getHighlightClasses(tileHighlights);
    return(<div className={elementClass}
                onMouseDown={this.props.onMouseDownOnTile.bind(null, this.props.row, this.props.column)}
                onClick={this.props.onClickOnTile.bind(null, this.props.row, this.props.column)}>{gamePieceIcon}</div>);
  }
});

var BoardRow = React.createClass({displayName: 'BoardRow',
  propTypes: {
    rowId:  React.PropTypes.number.isRequired,
    pieces: React.PropTypes.object.isRequired,
    board:  React.PropTypes.object.isRequired,
    highlights: React.PropTypes.object,
    onMouseDownOnTile: React.PropTypes.func,
    onClickOnTile:     React.PropTypes.func,
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
                              highlights={this.props.highlights}
                              piece={this.getPiece(column)}
                              onMouseDownOnTile={this.props.onMouseDownOnTile}
                              onClickOnTile={this.props.onClickOnTile} />);
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
    return { moveOptionsCache: {}, activePiece: undefined, tileHighlights: {} };
  },
  pieceOnTile: function(row, column) {
    return(this.props.board[column + ',' + row] || 'none');
  },
  selectTile: function(row, column) {
    var pieceId = this.pieceOnTile(row, column);
    if(pieceId == 'none') return;
    this.state.activePiece = this.state.activePiece == pieceId ? undefined : pieceId;
    this.state.tileHighlights = this.getTileHighlightsFor(this.state.activePiece);
    this.setState(this.state);
  },
  getTileHighlightsFor: function(pieceId) {
    var moveOptions = this.state.moveOptionsCache[pieceId]
      , highlights = {};
    if(!moveOptions) return;
    moveOptions.forEach(function(element, index, array) {
      var tile = element.y + ',' + element.x;
      highlights[tile] = { probability: element.probability };
    });
    return highlights;
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
      .done(function(data, status, jqXHR)  { _this.state.moveOptionsCache[pieceId] = data; _this.state.tileHighlights = _this.getTileHighlightsFor(_this.state.activePiece); _this.setState(_this.state); if(callback) callback(data); })
      .fail(function(jqXHR, status, error) { console.debug("Failure: %o", error); });
    }
  },
  processMoveRequest: function(row, column) {
    var activePiece = this.props.pieces[this.state.activePiece]
      , moveString = activePiece.state + ':' + column + ',' + row + ':';
    console.debug("Move Requested: %o", moveString);
  },
  onMouseDownOnTile: function(row, column, event) {
    var pieceId = this.pieceOnTile(row, column);
    if(pieceId == 'none') return;
    console.debug("Move Options Requested for: %o", pieceId);
    this.getMoveOptions(pieceId);
  },
  onClickOnTile: function(row, column, event) {
    console.debug("Click: %o, %o", column, row);
    if(this.state.activePiece) {
      this.processMoveRequest(row, column);
    }else {
      this.selectTile(row, column);
    }
  },
  render: function() {
    var rows = [];
    for(var row=7; row>=0; row--) {
      rows.push(<BoardRow key={row}
                          rowId={row}
                          pieces={this.props.pieces}
                          board={this.props.board}
                          highlights={this.state.tileHighlights}
                          onMouseDownOnTile={this.onMouseDownOnTile}
                          onClickOnTile={this.onClickOnTile} />);
    }
    return(
      <div className="chess-board">
        {rows}
      </div>
    );
  }
});

// React.renderComponent(<MessGame />, document.querySelector('.react-mess-board'));