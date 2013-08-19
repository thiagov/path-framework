require "./node.rb"
require "./pqueue.rb"

class FlatMC
  def initialize(initial_node)
    @memory = {}
    @num_simulations = 25
    @simulation_depth = 10
  end

  def get_move(current_node, goal)
    new_node = flat_monte_carlo(current_node, goal)

    if !@memory[current_node.position]
      @memory[current_node.position] = {}
      @memory[current_node.position][new_node.position] = 1
    elsif !@memory[current_node.position][new_node.position]
      @memory[current_node.position][new_node.position] = 1
    else
      @memory[current_node.position][new_node.position] += 1
    end

    return new_node
  end


  def flat_monte_carlo(initial_node, goal)
    ch_visits = {}
    Observation.instance.all_directions.each do |direction|
      child = initial_node.child(direction)
      if child
        num_uses = @memory[initial_node.position][child.position] rescue nil
        ch_visits[direction] = num_uses.to_i
      end
    end
    min_visits = ch_visits.values.min
    frontier = ch_visits.select{|k, v| v == min_visits}.keys

    children = []
    frontier.each do |direction|
      child = initial_node.child(direction)
      num_negative_inf = 0
      num_positive_inf = 0
      @num_simulations.times do
        val = random_simulation(initial_node, direction, goal)
        if val == -1.0/0.0
          num_negative_inf += 1
        elsif val == 1.0/0.0
          num_positive_inf += 1
        else
          child.value += val
        end
      end
      if num_negative_inf == @num_simulations
        child.value = -1.0/0.0
      elsif num_positive_inf == @num_simulations
        child.value = 1.0/0.0
      else
        if @num_simulations.to_f - num_negative_inf.to_f - num_positive_inf.to_f == 0
          heuristic = 0
        else
          heuristic = child.value.to_f/(@num_simulations.to_f - num_negative_inf.to_f - num_positive_inf.to_f)
        end
        child.value = num_positive_inf*1000 + heuristic
      end
      children << child
    end
    #pp children.map{|ch| ch.value}
    return children.max_by{|node| node.value}
  end

  #
  # Compute the h-value. This value is the Chebyshev distance
  # from certain state to the goal state.
  #
  def h_value(current, goal)
    [(goal.i - current.i).abs, (goal.j - current.j).abs].max
  end

  def random_simulation(root, initial_direction, goal)
    debug = []

    infinite = 1.0/0.0
    current_node = root.child(initial_direction)

    return infinite if current_node.equals?(goal)

    reward = 0.0
    cnt = 0
    current_direction = initial_direction
    while !current_node.equals?(goal) && cnt < @simulation_depth
      valid_children = []
      valid_directions = Observation.instance.corridor_directions(current_direction)
      valid_directions.each do |direction|
        ch = current_node.child(direction)
        if ch
          valid_children << {:node => ch, :direction => direction}
        end
      end
      if valid_children.size == 0
        return -1.0/0.0
      end
      next_node = valid_children.sample
      current_node      = next_node[:node]
      current_direction = next_node[:direction]
      cnt += 1

      debug << next_node[:node]
    end

    #Observation.instance.print_grid(root, goal, nil, debug)
    #STDIN.getc

    reward = evaluate(current_node, goal)
    return reward
  end

  def evaluate(node, goal)
    d = h_value(node, goal).to_f
    reward = (1.0/d.to_f)
    return reward + clean_line_of_sight(node, goal)
  end

  def clean_line_of_sight(current_node, goal)
    interval_i = current_node.i > goal.i ? goal.i..current_node.i : current_node.i..goal.i
    interval_j = current_node.j > goal.j ? goal.j..current_node.j : current_node.j..goal.j

    obstacle = 0
    for i in interval_i
      obstacle += 1 unless Observation.instance.is_passable?(i,current_node.j)
    end
    i = interval_i.last == current_node.i ? interval_i.first : interval_i.last
    for j in interval_j
      obstacle += 1 unless Observation.instance.is_passable?(i, j)
    end

    obstacle2 = 0
    for j in interval_j
      obstacle2 += 1 unless Observation.instance.is_passable?(current_node.i, j)
    end
    j = interval_j.last == current_node.j ? interval_j.first : interval_j.last
    for i in interval_i
      obstacle2 += 1 unless Observation.instance.is_passable?(i, j)
    end

    return 1.0 if obstacle == 0 && obstacle2 == 0
    return 0.0 if obstacle > 0 && obstacle2 > 0
    return 0.5
  end
end
