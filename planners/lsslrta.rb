# encoding: utf-8

require "./node.rb"

class LssLrta

  def initialize(lookahead)
    @closed_list = []
    @open_list   = []
    @partial_path = []
    @grid_heuristic = []
    Observation.instance.grid_height.times do |h|
      @grid_heuristic[h] = []
      Observation.instance.grid_width.times do |w|
        @grid_heuristic[h][w] = nil
      end
    end
    @lookahead = lookahead > 0 ? lookahead : 100
  end

  def restart(root, final_node)
    @closed_list = []
    @open_list   = []
    @partial_path = []
  end

  def get_move(current_node, goal)
    expanded_states  = 0
    planning_episode = false

    new_node = nil
    if !@partial_path.empty?
      candidate = @partial_path.pop
      if Observation.instance.is_passable?(candidate.i, candidate.j)
        new_node = candidate
      end
    end

    if new_node.nil?
      planning_episode = true
      @partial_path = []

      a_star_result = limited_a_star(current_node, goal, @lookahead)
      expanded_states = a_star_result[:num_expanded]
      @closed_list    = a_star_result[:expanded]
      @open_list      = a_star_result[:frontier]

      x = a_star_result[:node]
      while x != nil
        @partial_path << x
        x = x.parent
      end
      @partial_path.pop

      update_heuristics(@closed_list, @open_list, goal)
      new_node = @partial_path.pop
    end

    return new_node, @closed_list, {:planning_episode => planning_episode, :expanded_states => expanded_states}
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

  #
  # A* procedure.
  # Returns:
  #   node:         The goal node if it was found, or nil otherwise
  #   num_expanded: The number of nodes expanded
  #   expanded:     The expanded nodes on the A* procedure (the CLOSED list)
  #   frontier:     The nodes on the frontier, on the A* procedure (the OPEN list)
  #
  def limited_a_star(initial_node, final_node, lookahead)
    num_expanded = 0
    x = Node.new(initial_node.i, initial_node.j)
    x.depth = 0
    x.value = 0.0
    return {:node => x, :num_expanded => num_expanded, :expanded => [], :frontier => []} if x.position == final_node.position

    frontier = nil
    frontier = PQueue.new{|a, b| h_value(a, final_node) + a.value < h_value(b, final_node) + b.value}
    frontier.push(x)

    explored = {}
    frontier_hash = {}
    frontier_hash[x.position] = true
    expanded = []

    loop do
      return nil if frontier.empty?
      current_node = frontier.pop
      frontier_hash[current_node.position] = false
      return {:node => current_node, :num_expanded => num_expanded, :expanded => expanded, :frontier => frontier} if current_node.position == final_node.position
      explored[current_node.position] = true
      expanded << current_node
      num_expanded += 1
      lookahead -= 1

      Observation.instance.all_directions.each do |direction|
        child = current_node.child(direction)
        if child
          child.depth = child.parent.depth + 1
          child.value = child.parent.value + Observation.instance.direction_cost(direction)
          if !frontier_hash[child.position] && !explored[child.position]
            frontier.push(child)
            frontier_hash[child.position] = true
          end
        end
      end
      if lookahead == 0
        #puts "="
        #puts "Lookahead 0"
        return {:node => current_node, :num_expanded => num_expanded, :expanded => expanded, :frontier => frontier}
      end
    end
  end

  #
  # Djikstra algorithm used to update the heuristic value from all the states
  # in the local search space.
  #
  def update_heuristics(closed_list, open_list, final_node)
    # The new open list must use the h-value, and not the f-value
    remade_open_list = PQueue.new{|a, b| h_value(a, final_node) < h_value(b, final_node)}
    while !open_list.empty?
      remade_open_list.push(open_list.pop)
    end

    # The new closed list will have the position instead of the nodes. This is
    # usefull to make comparisons between positions more efficiently. Furthermore,
    # all positions in the search space will have the h-value set to infinity.
    remade_closed_list = []
    remade_closed_list_hash = {}
    closed_list.each do |node|
      remade_closed_list << node.position
      remade_closed_list_hash[node.position] = true
      @grid_heuristic[node.i][node.j] = 1.0/0.0
    end

    while !remade_closed_list.empty?
      s = remade_open_list.pop
      if remade_closed_list_hash[s.position]
        remade_closed_list.delete(s.position)
        remade_closed_list_hash[s.position] = false
      end
      Observation.instance.all_directions.each do |direction|
        child = s.child(direction)
        if child
          if remade_closed_list_hash[child.position] && h_value(child, final_node) > (h_value(s, final_node) + Observation.instance.direction_cost(direction))
            @grid_heuristic[child.i][child.j] = h_value(s, final_node) + Observation.instance.direction_cost(direction)
            remade_open_list.push(child)
          end
        end
      end
    end
  end
end
