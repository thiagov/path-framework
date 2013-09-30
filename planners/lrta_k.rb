require "./node.rb"

class LrtaK

  def initialize
    @grid_heuristic = []
    Observation.instance.grid_height.times do |h|
      @grid_heuristic[h] = []
      Observation.instance.grid_width.times do |w|
        @grid_heuristic[h][w] = nil
      end
    end

    @path_hash = {}
    @supp_hash = {}
    @k = 10
  end

  def get_move(current_node, goal)
    @expanded_states = 0
    planning_episode = true

    @path_hash[current_node.position] = true

    lookahead_update_k(current_node, goal)

    direction = Observation.instance.all_directions.min_by do |dir|
      child = current_node.child(dir)
      if child
        h_value(child, goal) + Observation.instance.direction_cost(dir)
      else
        1.0/0.0
      end
    end
    child = current_node.child(direction)

    return child, nil, {:planning_episode => planning_episode, :expanded_states => @expanded_states}
  end

  def lookahead_update_k(current_node, goal)
    q = [current_node]
    cont = @k - 1
    while !q.empty?
      v = q.shift
      if lookahead_update_one(v, goal)
        Observation.instance.all_directions.each do |dir|
          child = v.child(dir)
          if child && @path_hash[child.position] && cont > 0 && v.position == @supp_hash[child.position]
            q.push(child)
            cont -= 1
          end
        end
      end
    end
  end

  def lookahead_update_one(current_node, goal)
    @expanded_states += 1
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

    @supp_hash[current_node.position] = child.position

    if new_h > h_value(current_node, goal)
      @grid_heuristic[current_node.i][current_node.j] = new_h
      return true
    end
    return false
  end

  def h_value(current, goal)
    if @grid_heuristic[current.i][current.j].nil?
      [(goal.i - current.i).abs, (goal.j - current.j).abs].max
    else
      @grid_heuristic[current.i][current.j]
    end
  end


end
