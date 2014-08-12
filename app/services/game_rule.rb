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
# result: the resulting position (string/weak) when a collision occurs (default: strong)
#   strong   - [ 90% ] chance of victory
#   weak     - [ 20% ] chance of victory
#   [x, y, ..., z] %x chance of victory on first tile, %y on second, etc, %z on all tiles after the last percentage
#       ex. [%75, %50, %25] => %75, %50, %25, %25, %25 if moving 5 tiles
# special: any special conditions (default: none)

class GameRule
  def initialize(rule_hash)
    raise "Invalid Rule" unless rule_hash[:direction].present? || rule_hash
    @direction          = rule_hash[:direction]
    @steps              = rule_hash[:steps] || { min: 1, max: 0 }
    @collisions         = rule_hash[:collisions] || :blocking
    @probability_result = rule_hash[:result] || [ 0.75 ]
    @special            = rule_hash[:special] || {}
  end

  def is_valid?(from, to)
  end

  # returns an array of all valid positions from the supplied position 
  # options
  #   include_probabilities: true/false
  def all_valid_moves_from(position, options = {})
  end

end