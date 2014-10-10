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
#   weak     - [ 25% ] chance of victory
#   [x, y, ..., z] %x chance of victory on first tile, %y on second, etc, %z on all tiles after the last percentage
#       ex. [%75, %50, %25] => %75, %50, %25, %25, %25 if moving 5 tiles
# special: any special conditions (default: none)

class GameRule
  def initialize(rule_params)
    raise "Invalid Rule: Must have a direction specified." unless rule_params[:direction].present?
    # TODO add validation code here to validate params, ex: collisions is correct type, steps is formatted correctly, etc...
    @steps              = expand_steps(rule_params[:steps] || { min: 1, max: 0 })
    @collisions         = rule_params[:collisions] || :blocking
    @probability_result = decode_probability_result(rule_params[:result]) || [ 0.9 ]
    @special            = rule_params[:special] || {}

    if rule_params[:direction].is_a?(Array)
      # @direction = Array.new(rule_params[:direction].length)
      @direction = rule_params[:direction].collect { |sub_rule| sub_rule.is_a?(GameRule) ? sub_rule : GameRule.new(sub_rule) }
      @validation_method = self.method(:valid_compound?)
    else
      @direction = rule_params[:direction]
      @validation_method = self.method("valid_#{@direction.to_s}?".to_sym)
    end
  end

  def validate_params(on:, from:, to:)
    raise ArgumentError.new, "on must be a game model." if on.blank?
    raise ArgumentError.new, "to must include x and y points." if(to[:x].blank? || to[:y].blank?)
    raise ArgumentError.new, "from must include x, y, and orientation." if(from[:x].blank? || from[:y].blank? || from[:orientation].blank?)
  end

  # from: { x: [x],  y: [y], orientation: [1/-1]  }
  # to:   { x: [x'], y: [y'] }
  # orientation: [1/-1]
  #    1 - white (moving up the board)
  #   -1 - black (moving down the board)
  def is_valid?(on:, from:, to:)
    validate_params(on: on, from: from, to: to)
    return false unless(on.on_board?(to) && on.on_board?(from))
    @validation_method.call(on: on, from: from, to: to)
  end

  # returns an array of all valid positions from the supplied position 
  # note: currently does not pay attention to collisions
  # from_position: Set [ { x: [x], y: [y], orientation [1/-1] } ]
  def all_valid_moves(on:, from_positions:, include_probabilities: false)
    if from_positions.is_a? Hash
      new_positions = get_all_valid_moves_from_single_position(on: on, position: from_positions)
    else
      new_positions = Set.new
      from_positions.each { |position| new_positions.merge(all_valid_moves(on: on, from_positions: position)) }
    end
    return  new_positions
  end

  def collisions(on:, from:, to:)
    return collisions_on_compound_rule(on, from, to) if @direction.is_a?(Array)
    return [] if @collisions == :disabled
    traveled_tiles = results_of_move(on: on, from: from, to: to)
    return :invalid_move unless same_tile?(to, traveled_tiles.last[:tile])
    rough_collisions = traveled_tiles.select { |step| step[:piece] != :none }
    return :invalid_collisions if !rough_collisions.empty? && invalid_collisions_on_walk(rough_collisions, from, to)
    rough_collisions = (same_tile?(to, rough_collisions.last[:tile]) ? [rough_collisions.last] : [] ) if @collisions == :jumping
    return rough_collisions
  end

  def invalid_collisions_on_walk(rough_collisions, from, to)
    # note: rough_collisions must not be empty
# puts "0 #{( @collisions == :blocking && (rough_collisions.length > 1 || !same_tile?(to, rough_collisions.first[:tile])) )}"
# puts "1 #{( @collisions == :none     &&  rough_collisions.length > 0 )}"
# puts "2 #{( @collisions == :all      && any_self_hits(from[:orientation], rough_collisions) )}"
# puts "3 #{((@collisions == :blocking || @collisions == :jumping) && same_tile?(to, rough_collisions.last[:tile]) && rough_collisions.last[:tile][:orientation] == from[:orientation] )}"
# puts "    a #{(@collisions == :blocking || @collisions == :jumping)}"
# puts "    b #{same_tile?(to, rough_collisions.last[:tile]) }"
# puts "    c #{rough_collisions.last[:tile][:orientation] == from[:orientation]}"

    ( @collisions == :blocking && (rough_collisions.length > 1 || !same_tile?(to, rough_collisions.first[:tile])) ) ||
    ( @collisions == :none     &&  rough_collisions.length > 0 ) ||
    ( @collisions == :all      && any_self_hits(from[:orientation], rough_collisions) ) ||
    ((@collisions == :blocking || @collisions == :jumping) && same_tile?(to, rough_collisions.last[:tile]) && rough_collisions.last[:piece][:orientation] == from[:orientation] )
  end

  def any_self_hits(orientation, collision_list)
# puts "    orientation: #{orientation }"
# puts "    collision_list: #{collision_list.map { |c| c[:tile][:orientation] } }"
    collision_list.detect { |collision| collision[:piece][:orientation] == orientation }.present?
  end

  def collisions_on_compound_rule(game, from, to)
    compound_collisions = []
    intermediate_tiles = find_compound_steps(game, from, to)
    return :invalid_move if intermediate_tiles.empty?
    current_position = from.dup
    intermediate_tiles.each_with_index do |tile, index|
      compound_collisions << @direction[index].collisions(on: game, from: current_position, to: tile)
      current_position = tile
    end
    return compound_collisions.flatten
  end

  def resolve_collision(collision)
    Random.rand < get_probability_result(collision[:tile][:rule_properties][:step])
  end

  def get_probability_result(step=0)
    # todo - eventually be able to add things like probability based on number of collisions instead of just number of steps
    @probability_result.fetch(step, @probability_result.last)
  end

  def results_of_move(on:, from:, to:)
    walk = all_traveled_tiles(on, from, to)
    return walk.collect { |tile| { tile: tile, piece: on.piece_on_tile(tile) } }
  end

  def all_traveled_tiles(game, from, to)
    return all_traveled_tiles_for_compound_rule(game, from, to) if @direction.is_a?(Array)
    results = []
    current_position = from.dup
    results << { rule_properties: { rule: self, step: results.length }, probability: get_probability_result(results.length) }.merge!(current_position) until (same_tile?(current_position, to) || game.piece_on_tile(next_tile!(current_position)) == :off_board || (@steps[:max] > 0 && results.length >= @steps[:max]))
    results = nil if results.length < @steps[:min]
    return results
  end

  def all_traveled_tiles_for_compound_rule(game, from, to)
    intermediate_tiles = find_compound_steps(game, from, to)
    return nil if intermediate_tiles.nil?
    traveled_tiles = []
    current_tile = from
    intermediate_tiles.each_with_index do |next_tile, index|
      traveled_tiles.concat @direction[index].all_traveled_tiles(game, current_tile, next_tile)
      current_tile = next_tile
    end
    return traveled_tiles
  end

  def find_compound_steps(game, from, to, step=0)
    possible_tiles = @direction[step].all_valid_moves(on: game, from_positions: from)
    return possible_tiles.find { |tile| same_tile?(tile, to) } if step == @direction.length-1

    possible_tiles.each do |test_tile|
      results = find_compound_steps(game, test_tile, to, step+1)
      return [test_tile, results].flatten if results.present?
    end
    return []
  end

  def set_has_tile?(tile_set, tile)
    return possible_tiles.find { |tile| same_tile?(tile, to) }.present?
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

  def get_all_valid_moves_from_single_position(on: , position: )
    return get_all_valid_moves_with_compound_direction(on: on, positions: position) if @direction.is_a?(Array)
    valid_positions = Set.new
    new_position = position.dup
    # note: no reason to check if these are valid steps because the very first real step checks if the entire walk is valid
    (1..@steps[:min]).each { |step| next_tile!(new_position) }
    # note: is_valid? is horribly inefficient, but it works and it gets edge cases,
    # so I'm not replacing it until I notice a performance reason to do so
    step = @steps[:min]
    new_position[:probability] = get_probability_result(step)
    while (is_valid?(on: on, from: position, to: new_position)) do
      new_position[:probability] = get_probability_result(step)
      step+=1
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

  # private
    def decode_probability_result(probability)
      case probability
      when :strong
        [ 0.9 ]
      when :weak
        [ 0.25 ]
      else
        probability
      end
    end
    def same_tile?(a, b); a.present? && b.present? && a[:x] == b[:x] && a[:y] == b[:y]; end

    def next_tile!(from)
      self.send(@direction, from)
    end

    def advance_position!(from, steps)
      (1..steps).each { |i| next_tile!(from) }
    end

    # from: { x: [x], y: [y], orientation: [1/-1] }
    def invalid_collisions?(game_board, from, steps)
      return false if @collisions == :disabled 
      from_position = from.dup
      (1..steps-1).each do |step|
        piece = game_board.piece_on_tile(next_tile!(from_position))
        unless piece == :none
          return true if [:blocking, :none].include?(@collisions) ||
                         (piece[:orientation] == from[:orientation] && @collisions == :all)
        end
      end
      piece = game_board.piece_on_tile(next_tile!(from_position))
      return piece != :none && (@collisions == :none || piece[:orientation] == from[:orientation])
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

    def magnitude(vector)
      Math.sqrt(vector[:x].abs2 + vector[:y].abs2).floor
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
      current_positions.detect { |position| position[:x] == to[:x] && position[:y] == to[:y] }.present?
    end
end