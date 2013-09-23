require "./node.rb"

class Prta
  def initialize(initial_node)
    @path = [initial_node]
    @not_passable = {}
    # Usado somente para ser retornado e desenhado pela gui
    @not_passable_array = []
  end

  def get_move(current_node, goal)
    expanded_states   = 0
    planning_episode  = false

    planning_episode   = true
    expanded_states   += 1
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
        @not_passable_array << current_node
      end
      @path << child
      candidate = child
    else
      @not_passable[current_node.position] = true
      @not_passable_array << current_node
      @path.pop
      candidate = @path.last
    end

    return candidate, nil, {:planning_episode => planning_episode, :expanded_states => expanded_states}
  end

  #
  # Compute the h-value. This value is the Chebyshev distance
  # from certain state to the goal state.
  #
  def h_value(current, goal)
    [(goal.i - current.i).abs, (goal.j - current.j).abs].max
  end
end
