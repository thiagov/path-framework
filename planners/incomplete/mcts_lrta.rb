# encoding: utf-8
require "./node.rb"
require "./pqueue.rb"

include Math

class Mcts

  class MctsNode
    attr_accessor :untried_moves, :child_nodes, :parent, :result, :visits, :move, :position

    def initialize(move, parent, position)
      @move = move
      @parent = parent
      @child_nodes = []
      @position = position
      @untried_moves = Observation.instance.all_directions.select{|dir| Observation.instance.is_valid_direction?(dir, position[0], position[1])}
      @visits = 0
      @result = 0.0
    end

    def add_child(move, position)
      n = MctsNode.new(move, self, position)
      @untried_moves.delete(move)
      @child_nodes << n
      return n
    end

    def update(result)
      r = result
      if result == 1.0/0.0
        r = 1.0
      elsif result == -1.0/0.0
        r = 0.0
      else
        r = result
      end
      @visits += 1
      @result += r
    end

    def select_child
      x = @child_nodes.sort_by do |c|
        c.result/c.visits + sqrt(2*log(@visits)/c.visits)
      end
      return x.last
    end

  end

  def initialize(initial_node)
    @simulation_depth = 35
    @num_simulations = 100
    @partial_path = []
    @grid_heuristic = []
    Observation.instance.grid_height.times do |h|
      @grid_heuristic[h] = []
      Observation.instance.grid_width.times do |w|
        @grid_heuristic[h][w] = nil
      end
    end
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
      moves, closed_list, open_list = mcts(current_node, goal)

      n = current_node
      moves.each do |move|
        ch = n.child(move)
        @partial_path.unshift(ch)
        n = ch
      end

      update_heuristics(closed_list, open_list, goal)
      new_node = @partial_path.pop
    end
    return new_node
  end

  def mcts(root, goal)
    root_node = MctsNode.new(nil, nil, root.position)
    @num_simulations.times do
      mcts_node = root_node
      node      = root
      val       = nil

      # Select
      while mcts_node.untried_moves == [] && mcts_node.child_nodes != []
        mcts_node = mcts_node.select_child()
        node      = node.child(mcts_node.move)
      end

      # Expand and Rollout
      if mcts_node.untried_moves != []
        m = mcts_node.untried_moves.sample

        # rollout
        val = random_simulation(node, m, goal)

        #expand
        node = node.child(m)
        mcts_node = mcts_node.add_child(m, node.position)
      end

      # Backpropagate
      while mcts_node != nil
        mcts_node.update(val)
        mcts_node = mcts_node.parent
      end
    end

    closed_list, open_list = get_lists(root_node)

    moves = []
    n = root_node
    while n.child_nodes != []
      best_ch = n.child_nodes.sort_by{|ch| ch.visits}.last
      moves << best_ch.move
      n = best_ch
    end

    return moves, closed_list, open_list
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
    end
    reward = evaluate(current_node, goal)
    return reward
  end

  def evaluate(node, goal)
    d = h_value(node, goal).to_f
    reward = (1.0/d.to_f)
    return reward
  end

  #
  # Compute the h-value. This value is the Chebyshev distance
  # from certain state to the goal state.
  #
  def h_value(current, goal)
    if @grid_heuristic[current.i][current.j].nil?
      [(goal.i - current.i).abs, (goal.j - current.j).abs].max
    else
      @grid_heuristic[current.i][current.j]
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
    remade_closed_list = closed_list
    remade_closed_list.each do |position|
      @grid_heuristic[position[0]][position[1]] = 1.0/0.0
    end

    while !remade_closed_list.empty?
      s = remade_open_list.pop
      remade_closed_list.delete(s.position) if remade_closed_list.include?(s.position)
      s.children.each do |child|
        # The comparison here considers all actions have weight 1. This can be modified if we want the
        # actions to have different values.
        if remade_closed_list.include?(child.position) && h_value(child, final_node) > (h_value(s, final_node) + 1)
          @grid_heuristic[child.i][child.j] = h_value(s, final_node) + 1
          remade_open_list.push(child)
        end
      end
    end
  end

  def get_lists(mcts_node)
    closed_list = []
    closed_list_hash = {}

    open_list = []
    open_list_hash = {}

    queue = [mcts_node]

    while !queue.empty?
      cur_mcts_node = queue.shift
      pos = cur_mcts_node.position
      cur_node = Node.new(pos[0], pos[1])

      if !closed_list_hash[pos]
        closed_list_hash[pos] = true
        open_list_hash[pos] = false
      end

      cur_mcts_node.untried_moves.each do |move|
        x = cur_node.child(move)
        if !closed_list_hash[x.position] && !open_list_hash[x.position]
          open_list_hash[x.position] = true
        end
      end

      cur_mcts_node.child_nodes.each do |ch|
        queue.push ch
      end
    end

    closed_list_hash.each_pair do |pos, bool|
      if bool
        closed_list << pos
      end
    end

    open_list_hash.each_pair do |pos, bool|
      if bool
        open_list << Node.new(pos[0], pos[1])
      end
    end

    return closed_list, open_list
  end
end
