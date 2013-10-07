# encoding: utf-8

require "./node.rb"
require "priority_queue"

class DLite

  def initialize(initial_node, goal)
    @start = initial_node

    @queue = PriorityQueue.new
    @km = 0

    @g_values = {}
    @rhs = {}

    @rhs[goal.position] = 0
    @queue.push goal.position, [h_value(initial_node, goal), 0]

    @first_run = true
    @last = @start
    @grid = []
    Observation.instance.grid_height.times do |h|
      @grid[h] = []
      Observation.instance.grid_width.times do |w|
        @grid[h][w] = " "
      end
    end

  end

  def calculate_key(node)
    g   = get_g_value(node.position)
    rhs = get_rhs(node.position)
    h   = h_value(@start, node)
    return [[g, rhs].min + h + @km, [g, rhs].min]
  end

  def update_vertex(node, goal)
    is_in_queue = @queue.has_key?(node.position)
    if !node.equals?(goal)
      direction = Observation.instance.all_directions.min_by do |dir|
        child = node.child(dir)
        if child
          Observation.instance.direction_cost(dir) + get_g_value(child.position)
        else
          1.0/0.0
        end
      end
      @rhs[node.position] = Observation.instance.direction_cost(direction) + get_g_value(node.child(direction).position) rescue nil
    end
    if is_in_queue
      @queue.delete(node.position)
    end
    if get_g_value(node.position) != get_rhs(node.position)
      @queue.push node.position, calculate_key(node)
    end
  end

  def first_less_than_second(key1, key2)
    if key1[0] != key2[0] && key1[0] < key2[0]
      return true
    elsif key1[0] == key2[0] && key1[1] < key2[1]
      return true
    end
    return false
  end

  def get_g_value(node_pos)
    val = @g_values[node_pos] || 1.0/0.0
  end

  def get_rhs(node_pos)
    val = @rhs[node_pos] || 1.0/0.0
  end

  def compute_shortest_path(goal)
    while first_less_than_second(@queue.min[1], calculate_key(@start)) || get_rhs(@start.position) > get_g_value(@start.position)
      u, k_old = @queue.delete_min
      u_node = Node.new(u[0], u[1])
      k_new = calculate_key(u_node)
      if first_less_than_second(k_old, k_new)
        @queue.push u, k_new
      elsif get_g_value(u) > get_rhs(u)
        @g_values[u] = get_rhs(u)
        # Considerando predecessores = sucessores
        Observation.instance.all_directions.each do |dir|
          s = u_node.child(dir)
          if s
            update_vertex(s, goal)
          end
        end
      else
        @g_values[u] = nil
        # Considerando predecessores = sucessores
        Observation.instance.all_directions.each do |dir|
          s = u_node.child(dir)
          if s
            update_vertex(s, goal)
          end
        end
        update_vertex(u_node, goal)
      end
    end
  end

  #
  # Compute the h-value. This value is the Chebyshev  distance
  # from certain state to the goal state, or a value previously defined.
  #
  def h_value(current, goal)
    [(goal.i - current.i).abs, (goal.j - current.j).abs].max
  end

  def get_move(current_node, final_node)
    compute_shortest_path(final_node) if @first_run

    changed = []
    Observation.instance.all_directions.each do |dir|
      child = current_node.any_child(dir)
      g = Observation.instance.grid[child.i][child.j]
      if g != @grid[child.i][child.j] && g != '.'
        changed.concat child.predecessors
      end
      @grid[child.i][child.j] = g
    end
    changed = [] if @first_run
    @first_run = false

    if !changed.empty?
      @km = @km + h_value(@last, @start)
      @last = @start

      changed.each do |node_tuple|
        node      = node_tuple[0]
        update_vertex(node, final_node)
      end
      compute_shortest_path(final_node)
    end

    direction = Observation.instance.all_directions.min_by do |dir|
      child = current_node.child(dir)
      if child
        Observation.instance.direction_cost(dir) + get_g_value(child.position)
      else
        1.0/0.0
      end
    end
    new_node = current_node.child(direction)
    @start = new_node

    return new_node
  end
end
