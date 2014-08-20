# direction:
#   forward, backward, left, right,
#   diagonal_forward_left, diagonal_forward_right, diagonal_backward_left, diagonal_backward_right
#   [ ]: compound move set
#       note: compound moves are very slow to calculate. it is expected to add a "Vector" based move to handle
#             simple compound moves such as the "knight" move.
# steps: number of steps to be be taken where 0 means any number (default: { min: 1, max: 0 })
#   note: steps x => steps: { min: x, max: x }
# collisions: how to handle collisions (default: blocking)
#   blocking - way must be clear to target
#   disabled - ignore all (note: this is only useful for compound moves such as the knights, otherwise it means two pieces would occupy the same square.)
#   jumping  - ignore all but last in direction
#   all      - attack all squares between current position and target
#   none     - no collisions are allowed for this piece
#
#   For the future: Think about Collision Types - would it be nice to be able to have lots of different types of collisiosn
#       { type: [blocking/disabled/jumping/all], min: [x], max: [y] }
#
# result: the resulting position (string/weak) when a collision occurs (default: strong)
#   strong   - [ 90% ] chance of victory
#   weak     - [ 20% ] chance of victory
#   [x, y, ..., z] %x chance of victory on first tile, %y on second, etc, %z on all tiles after the last percentage
#       ex. [%75, %50, %25] => %75, %50, %25, %25, %25 if moving 5 tiles
# special: any special conditions (default: none)

class GameRule
  def initialize(rule_params)
    raise "Invalid Rule: Must have a direction specified." unless rule_params[:direction].present?
    # TODO add validation code here to validate params, ex: collisions is correct type, steps is formatted correctly, etc...
    @steps              = expand_steps(rule_params[:steps] || { min: 1, max: 0 })
    @collisions         = rule_params[:collisions] || :blocking
    @probability_result = rule_params[:result] || [ 0.75 ]
    @special            = rule_params[:special] || {}

    if rule_params[:direction].is_a?(Array)
      # @direction = Array.new(rule_params[:direction].length)
      @direction = rule_params[:direction].collect { |sub_rule_params| GameRule.new(sub_rule_params) }
      @validation_method = self.method(:valid_compound?)
    else
      @direction = rule_params[:direction]
      @validation_method = self.method("valid_#{@direction.to_s}?".to_sym)
    end
  end

  # from: { x: [x],  y: [y], orientation: [1/-1]  }
  # to:   { x: [x'], y: [y'] }
  # orientation: [1/-1]
  #    1 - white (moving up the board)
  #   -1 - black (moving down the board)
  def is_valid?(on:, from:, to:)
    raise ArgumentError.new, "on must be a game model." if on.blank?
    raise ArgumentError.new, "to must include x and y points." if(to[:x].blank? || to[:y].blank?)
    raise ArgumentError.new, "from must include x, y, and orientation." if(from[:x].blank? || from[:y].blank? || from[:orientation].blank?)
    return false unless(on.on_board?(to) && on.on_board?(from))
    @validation_method.call(on: on, from: from, to: to)
  end

  # returns an array of all valid positions from the supplied position 
  # from_position: Set [ { x: [x], y: [y], orientation [1/-1] } ]
  # options
  #   include_probabilities: true/false
  def all_valid_moves(on:, from_positions:, options: {})
    if from_positions.is_a? Hash
      new_positions = get_all_valid_moves_from_single_position(on: on, position: from_positions)
    else
      new_positions = Set.new
      from_positions.each { |position| new_positions.merge(all_valid_moves(on: on, from_positions: position, options: options)) }
    end
    return  new_positions
  end

  def get_all_valid_moves_from_single_position(on: , position: )
    return get_all_valid_moves_with_compound_direction(on: on, positions: position) if @direction.is_a?(Array)
    valid_positions = Set.new
    new_position = position.dup
    (1..@steps[:min]).each { |step| next_tile!(new_position) }
    while (is_valid?(on: on, from: position, to: new_position)) do
      valid_positions << new_position
      new_position = next_tile!(new_position.dup)
    end
    return valid_positions
  end

  def get_all_valid_moves_with_compound_direction(on:, positions: )
    current_positions = positions
    @direction.each do |direction|
      current_positions = direction.all_valid_moves(on: on, from_positions: current_positions)
    end
    return current_positions
  end

  def uses_blocking_collisions?
    !([:disabled, :jumping, :all].include? @collisions)
  end

  def vertical_change?(from, to)
    from[:x] == to[:x]
  end

  def horizontal_change?(from, to)
    from[:y] == to[:y]
  end

  def diagonal_change?(from, to)
    (from[:y] - to[:y]).abs == (from[:x] - to[:x]).abs
  end

  def within_step_limits?(steps)
    steps >= @steps[:min] && (@steps[:max] == 0 || steps <= @steps[:max])
  end

  private
    def next_tile!(from)
      self.send(@direction, from)
    end

    # from: { x: [x], y: [y], orientation: [1/-1] }
    def invalid_collisions?(game_board, from, steps)
      return false unless uses_blocking_collisions?
      from_position = from.dup
      (1..steps-(@collisions == :none ? 0 : 1)).each { |step| return true unless game_board.piece_on_tile(next_tile!(from_position)) == :none }
      return false
    end

    def expand_steps(steps)
      steps.is_a?(Numeric) ? { min: steps, max: steps } : steps
    end

    def steps_on_axis(to, from, axis)
      (to[axis] - from[axis]) * from[:orientation]
    end

    def step_vector_from(to, from)
      { x: to[:x] - from[:x], y: to[:y] - from[:y] }
    end

    def magnitude(diagonal)
      # do not need full magnitude calculation becuase vector must be diagonal
      diagonal[:x].abs
    end

    def is_diagonal_direction?(vector, orientation, direction)
      vector[:x] * direction[:x] * orientation > 0 && vector[:y] * direction[:y] * orientation > 0
    end

    # note: these methods will modify the parameter, they are missing the ! because of the way they need to be called
    # not as big a deal since they are private to this fairly small class
    def forward (from); from[:y] += from[:orientation]; from; end
    def backward(from); from[:y] -= from[:orientation]; from; end
    def left    (from); from[:x] -= from[:orientation]; from; end
    def right   (from); from[:x] += from[:orientation]; from; end
    def diagonal_forward_left  (from); forward(from); left(from); end
    def diagonal_forward_right (from); forward(from); right(from); end
    def diagonal_backward_left (from); backward(from); left(from); end
    def diagonal_backward_right(from); backward(from); right(from); end


    def valid_diagonal?(on:, from:, to:, diagonal:)
      return false unless diagonal_change?(from, to)
      step_vector = step_vector_from(to, from)
      return false unless within_step_limits?(magnitude(step_vector))
      return false unless is_diagonal_direction?(step_vector, from[:orientation], diagonal)
      return false if invalid_collisions?(on, from, step_vector[:x].abs)
      return true
    end

    def valid_non_diagonal?(on:, from:, to:, axis:, direction:)
      return false unless ((axis == :y && vertical_change?(from, to)) || (axis == :x && horizontal_change?(from, to)))
      steps = steps_on_axis(to, from, axis) * direction
      return false unless within_step_limits?(steps)
      return false if invalid_collisions?(on, from, steps)
      return true
    end

    # from: { x: [x], y: [y], orientation: [1/-1] }
    def valid_forward?(on:, from:, to:)
      valid_non_diagonal?(on: on, from: from, to: to, axis: :y, direction: 1)
    end

    def valid_backward?(on:, from:, to:)
      valid_non_diagonal?(on: on, from: from, to: to, axis: :y, direction: -1)
    end

    def valid_left?(on:, from:, to:)
      valid_non_diagonal?(on: on, from: from, to: to, axis: :x, direction: -1)
    end

    def valid_right?(on:, from:, to:)
      valid_non_diagonal?(on: on, from: from, to: to, axis: :x, direction: 1)
    end

    def valid_diagonal_forward_left?(on:, from:, to:)
      valid_diagonal?(on: on, from: from, to: to, diagonal: { x: -1, y: 1 })
    end

    def valid_diagonal_forward_right?(on:, from:, to:)
      valid_diagonal?(on: on, from: from, to: to, diagonal: { x: 1, y: 1 })
    end

    def valid_diagonal_backward_left?(on:, from:, to:)
      valid_diagonal?(on: on, from: from, to: to, diagonal: { x: -1, y: -1 })
    end

    def valid_diagonal_backward_right?(on:, from:, to:)
      valid_diagonal?(on: on, from: from, to: to, diagonal: { x: 1, y: -1 })
    end

    def valid_compound?(on:, from:, to:)
      current_positions = get_all_valid_moves_with_compound_direction(on: on, positions: from)
      current_positions.include?({ x: to[:x], y: to[:y], orientation: from[:orientation] })
    end

end