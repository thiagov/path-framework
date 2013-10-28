# encoding: utf-8

require "./node.rb"

class Flrta

  def initialize(initial_node)
    @open_list = PQueue.new{|a, b| h_value(a, final_node) + a.value < h_value(b, final_node) + b.value}
    @open_list_hash = {}
    @closed_list_hash = {}
    @closed_list = []

    @lookahead = 100
    @partial_path = []

    @grid_heuristic = []
    Observation.instance.grid_height.times do |h|
      @grid_heuristic[h] = []
      Observation.instance.grid_width.times do |w|
        @grid_heuristic[h][w] = nil
      end
    end

    @grid_g_values = []
    Observation.instance.grid_height.times do |h|
      @grid_g_values[h] = []
      Observation.instance.grid_width.times do |w|
        @grid_g_values[h][w] = 1.0/0.0
      end
    end
    @grid_g_values[initial_node.i][initial_node.j] = 0

    @alive_cells = Hash.new{|h, k| h[k] = true}
  end

  def get_move(current_node, goal)
    new_node = nil
    if !@partial_path.empty?
      candidate = @partial_path.pop
      if Observation.instance.is_passable?(candidate.i, candidate.j)
        new_node = candidate
      end
    end

    if new_node.nil?
      @partial_path = []
      goal_found, t = expand_lss(current_node, goal)

      if goal_found
        candidate = t
        open = []
      else
        g_cost_learning(goal)
        update_heuristics(goal)

        #TODO: Mark dead-ends and redundant states in open and closed
        mark_dead_ends()

        open = @open_list.dup
        candidate = nil
        while !open.empty?
          candidate = open.pop
          break if @alive_cells[candidate.position]
        end
      end

      if open.empty? && !goal_found
        new_node = current_node.children.min_by{|node| @grid_g_values[node.i][node.j]}
      else
        x = candidate
        while x != nil
          @partial_path << x
          x = x.parent
        end
        @partial_path.pop
        new_node = @partial_path.pop
      end
    end

    dead_states = []
    @alive_cells.each_pair do |k, v|
      dead_states << Node.new(k[0], k[1]) if !v
    end

    return new_node, dead_states

  end

  def expand_lss(current_node, goal)
    @open_list = PQueue.new{|a, b| h_value(a, goal) + a.value < h_value(b, goal) + b.value}
    @open_list_hash = {}
    @closed_list_hash = {}
    @closed_list = []

    x = Node.new(current_node.i, current_node.j)
    x.depth = 0
    x.value = 0.0
    @open_list.push(x)

    @lookahead.times do
      s = @open_list.pop
      @closed_list.push << s
      if !@alive_cells[s.position]
        next
      end
      expand_and_propagate(s, goal, true)
      if s.position == goal.position
        return true, s
      end
    end
    return false, nil
  end

  def expand_and_propagate(current_node, goal, expand)
    restart = true
    while restart
      restart = false
      # for each successor of current_node
      Observation.instance.all_directions.each do |direction|
        child = current_node.child(direction)
        # if expand
        if child
          if expand
            child.depth = child.parent.depth + 1
            child.value = child.parent.value + Observation.instance.direction_cost(direction)
            if !@open_list_hash[child.position] && !@closed_list_hash[child.position]
              @open_list.push(child)
              @open_list_hash[child.position] = true
            end
          end
          if @grid_g_values[current_node.i][current_node.j] + Observation.instance.direction_cost(direction) < @grid_g_values[child.i][child.j]
            was_dead = !@alive_cells[child.position]
            @alive_cells[child.position] = true
            @grid_g_values[child.i][child.j] = @grid_g_values[current_node.i][current_node.j] + Observation.instance.direction_cost(direction)
            @grid_heuristic[child.i][child.j] = nil
            if @closed_list_hash[child.position] && was_dead
              expand_and_propagate(child, goal, true)
            elsif @open_list_hash[child.position] || @closed_list_hash[child.position]
              expand_and_propagate(child, goal, false)
            end
          end
          if @grid_g_values[child.i][child.j] + Observation.instance.direction_cost(direction) < @grid_g_values[current_node.i][current_node.j] && @alive_cells[child.position]
            @grid_g_values[current_node.i][current_node.j] = @grid_g_values[child.i][child.j] + Observation.instance.direction_cost(direction)
            @grid_heuristic[current_node.i][current_node.j] = nil
            restart = true
            break
          end
        end
      end
    end
  end

  def g_cost_learning(goal)
    @open_list.to_a.each do |node|
      expand_and_propagate(node, goal, false)
    end
  end

  #
  # Djikstra algorithm used to update the heuristic value from all the states
  # in the local search space.
  #
  def update_heuristics(final_node)
    # The new open list must use the h-value, and not the f-value
    remade_open_list = PQueue.new{|a, b| h_value(a, final_node) < h_value(b, final_node)}
    open_list = @open_list.to_a
    while !open_list.empty?
      remade_open_list.push(open_list.pop)
    end

    # The new closed list will have the position instead of the nodes. This is
    # usefull to make comparisons between positions more efficiently. Furthermore,
    # all positions in the search space will have the h-value set to infinity.
    remade_closed_list = []
    @closed_list.each do |node|
      remade_closed_list << node.position
      @grid_heuristic[node.i][node.j] = 1.0/0.0
    end

    while !remade_closed_list.empty?

      # Ignoring dead states on OPEN. TODO: Check this later!
      #s = nil
      #while s.nil?
      #  s = remade_open_list.pop
      #  s = nil if !@alive_cells[s.position]
      #end
      s = remade_open_list.pop

      remade_closed_list.delete(s.position) if remade_closed_list.include?(s.position)
      Observation.instance.all_directions.each do |direction|
        child = s.child(direction)
        if child
          if remade_closed_list.include?(child.position) && h_value(child, final_node) > (h_value(s, final_node) + Observation.instance.direction_cost(direction))
            @grid_heuristic[child.i][child.j] = h_value(s, final_node) + Observation.instance.direction_cost(direction)
            remade_open_list.push(child)
          end
        end
      end
    end
  end


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

  def mark_dead_ends
    @open_list.to_a.each do |node|
      dead = true
      Observation.instance.all_directions.each do |direction|
        child = node.child(direction)
        if child && @alive_cells[child.position] && @grid_g_values[node.i][node.j] + Observation.instance.direction_cost(direction) <= @grid_g_values[child.i][child.j]
          dead = false
          break
        end
      end
      @alive_cells[node.position] = false if dead
    end
    @closed_list.each do |node|
      dead = true
      Observation.instance.all_directions.each do |direction|
        child = node.child(direction)
        if child && @alive_cells[child.position] && @grid_g_values[node.i][node.j] + Observation.instance.direction_cost(direction) <= @grid_g_values[child.i][child.j]
          dead = false
          break
        end
      end
      @alive_cells[node.position] = false if dead
    end
  end
end
