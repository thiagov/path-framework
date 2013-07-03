require "./node.rb"

class Prta
  def initialize(initial_node)
    @path = [initial_node]
    @not_passable = {}
  end

  def get_move(current_node, goal)
    child = nil
    Observation.instance.all_directions.each do |direction|
      ch = current_node.child(direction)
      if ch && !@not_passable[ch.position]
        ch.value = h_value(ch, goal) + Observation.instance.direction_cost(direction)
        child = ch if child.nil? || child.value > ch.value
      end
    end

    if !child.nil?
      if h_value(current_node, goal) < child.value
        @not_passable[current_node.position] = true
      end
      @path << child
      candidate = child
    else
      @not_passable[current_node.position] = true
      @path.pop
      candidate = @path.last
    end
    return candidate
  end

  #
  # Compute the h-value for the A* procedure. This value is the Chebyshev distance
  # from certain state to the goal state.
  #
  def h_value(current, goal)
    [(goal.i - current.i).abs, (goal.j - current.j).abs].max
  end


end
