# direction:
#   forward, backward, left, right,
#   diagonal_forward_left, diagonal_forward_right, diagonal_backward_left, diagonal_backward_right
#   [ ]: compound move set
# steps: number of steps to be be taken where 0 means any number (default: { min: 1, max: 0 })
#   note: steps x => steps: { min: x, max: x }
# collisions: how to handle collisions (default: blocking)
#   blocking - way must be clear to target
#   disabled - ignore all (note: this is only useful for compound moves such as the knights, otherwise it means two pieces would occupy the same square.)
#   jumping  - ignore all but last in direction
#   all      - attack all squares between current position and target
#
#   For the future: Think about Collision Types - would it be nice to be able to have lots of different types of collisiosn
#       { type: [blocking/disabled/jumping/all], min: [x], max: [y] }
# result: the resulting position (string/weak) when a collision occurs (default: strong)
#   strong   - [ 90% ] chance of victory
#   weak     - [ 20% ] chance of victory
#   [x, y, ..., z] %x chance of victory on first tile, %y on second, etc, %z on all tiles after the last percentage
#       ex. [%75, %50, %25] => %75, %50, %25, %25, %25 if moving 5 tiles
# special: any special conditions (default: none)

class GameRule
  def initialize(rule_hash)
    raise "Invalid Rule: Must have a direction specified." unless rule_hash[:direction].present?
    @direction          = rule_hash[:direction]
    @steps              = rule_hash[:steps] || { min: 1, max: 0 }
    @collisions         = rule_hash[:collisions] || :blocking
    @probability_result = rule_hash[:result] || [ 0.75 ]
    @special            = rule_hash[:special] || {}
  end

  # from: { x: [x],  y: [y], orientation: [1/-1]  }
  # to:   { x: [x'], y: [y'] }
  # where orientation:
  #    1 - white (moving up the board)
  #   -1 - black (moving down the board)
  def is_valid?(from, to)
  end

  # returns an array of all valid positions from the supplied position 
  # position { x: [x], y: [y], orientation [1/-1] }
  # options
  #   include_probabilities: true/false
  def all_valid_moves_from(position, options = {})
  end

  def uses_blocking_collisions?
    [:disabled, :jumping, :all].include? @collisions
  end

  def vertical_change?(from, to)
    from.x == to.x
  end

  def horizontal_change?(from, to)
    from.y == to.y
  end

  def diagonal_change?
    (from.y - to.y).abs == (from.x - to.x).abs
  end

  def within_step_limits?(steps)
    steps >= @steps.min && steps <= @steps.max
  end

  # from: { x: [x], y: [y], orientation: [1/-1] }
  def invalid_collisions?(from, steps)
    return false unless uses_blocking_collisions?
    raise "GAME BOARD MUST BE ATTACHED"
    from_position = from.clone
    (1..steps-1).each { |step| return true unless game_board.piece_on_tile(next_tile!(from_position)) == :none }
  end

  def next_tile!(from)
    self.send(@direction, from) if self.class.method_defined? @direction
  end


  # from: { x: [x], y: [y], orientation: [1/-1] }
  def valid_forward?(from, to)
    return false unless game.on_board?(to) && vertical_change?(from, to)
    forward_steps_taken = (to.y - from.y) * from.orientation
    return false unless within_step_limits?(forward_steps_taken)
    return false if invalid_collisions?(from, from.orientation, steps)
    return true
  end

  private
    # note: these methods will modify the parameter, they are missing the ! because of the way they need to be called
    # not as big a deal since they are private to this fairly small class
    def forward (from); from[:y] += from.orientation; end
    def backward(from); from[:y] -= from.orientation; end
    def left    (from); from[:x] -= from.orientation; end
    def right   (from); from[:x] += from.orientation; end
    def diagonal_forward_left  (from); forward(from); left(from); end
    def diagonal_forward_right (from); forward(from); right(from); end
    def diagonal_backward_left (from); backward(from); left(from); end
    def diagonal_backward_right(from); backward(from); right(from); end
end