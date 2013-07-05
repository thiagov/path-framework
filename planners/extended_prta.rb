# encoding: utf-8
require "./node.rb"
require "./pqueue.rb"

class ExtendedPrta
  def initialize(initial_node)
    @path = [initial_node]
    @not_passable = {}

    @num_simulations = 45
    @simulation_depth = 45
  end

  def get_move(current_node, goal)
    children = []
    Observation.instance.all_directions.each do |direction|
      ch = current_node.child(direction)
      if ch && !@not_passable[ch.position]
        ch.value = h_value(ch, goal) + Observation.instance.direction_cost(direction)

        val = 0.0
        num_wins = 0
        num_neg_inf = 0
        @num_simulations.times do
          new_val = random_simulation(current_node, direction, goal)
          if new_val == 1.0/0.0
            num_wins += 1
          elsif new_val == -1.0/0.0
            num_neg_inf += 1
          elsif new_val > val
            val = new_val
          end
        end

        children << {:child => ch, :value => val, :num_wins => num_wins, :num_neg_inf => num_neg_inf}
      end
    end

    max_val     = children.map{|ch| ch[:value]}.max
    max_wins    = children.map{|ch| ch[:num_wins]}.max
    child = nil

    if !max_wins.nil? && max_wins != 0
      child = children.select{|ch| ch[:num_wins] == max_wins}.sample[:child]
    elsif !max_val.nil? && max_val != 0.0
      child = children.select{|ch| ch[:value] == max_val}.sample[:child]
    else
      child = children.map{|ch| ch[:child]}.sample
    end
    #child = children.max_by{|ch| ch[:value]}[:child] rescue nil

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

    x = []
    @not_passable.each do |k, v|
      x << Node.new(k[0], k[1])
    end
    Observation.instance.print_grid(nil, nil, nil, x)
    STDIN.getc
    return candidate
  end

  #
  # Compute the h-value. This value is the Chebyshev distance
  # from certain state to the goal state.
  #
  def h_value(current, goal)
    [(goal.i - current.i).abs, (goal.j - current.j).abs].max
  end

  def random_simulation(root, initial_direction, goal)
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
        if ch# && !@not_passable[ch.position]
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
    end
    reward = evaluate(current_node, goal)
    return reward
  end

  def evaluate(node, goal)
    d = h_value(node, goal).to_f
    #is_unvisited = Observation.instance.is_observed(node.i, node.j)
    #if is_unvisited
    #  reward = 1 + (1.0/d.to_f)
    #else
      reward = (1.0/d.to_f)
    #end
    return reward
  end

end
