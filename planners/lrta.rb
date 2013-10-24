require "./node.rb"

class Lrta

  def initialize
    @grid_heuristic = []
    Observation.instance.grid_height.times do |h|
      @grid_heuristic[h] = []
      Observation.instance.grid_width.times do |w|
        @grid_heuristic[h][w] = nil
      end
    end
  end

  def restart(root, final_node)
  end

  def get_move(current_node, goal)
    expanded_states   = 0
    planning_episode  = false

    planning_episode   = true
    expanded_states   += 1
    direction = Observation.instance.all_directions.min_by do |dir|
      child = current_node.child(dir)
      if child
        h_value(child, goal) + Observation.instance.direction_cost(dir)
      else
        1.0/0.0
      end
    end

    child = current_node.child(direction)
    new_h = h_value(child, goal) + Observation.instance.direction_cost(direction)

    if new_h > h_value(current_node, goal)
      @grid_heuristic[current_node.i][current_node.j] = new_h
    end

    return child, nil, {:planning_episode => planning_episode, :expanded_states => expanded_states}
  end

  private

  #
  # Compute the h-value for the A* procedure. This value is the Chebyshev  distance
  # from certain state to the goal state, or a value previously defined.
  #
  def h_value(current, goal)
    if @grid_heuristic[current.i][current.j].nil?
      [(goal.i - current.i).abs, (goal.j - current.j).abs].max
    else
      @grid_heuristic[current.i][current.j]
    end
  end
end
