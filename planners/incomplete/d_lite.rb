# encoding: utf-8

require "./node.rb"
require "priority_queue"

class DLite

  def initialize(initial_node, goal)
    @start = initial_node

    @queue = PriorityQueue.new
    @km = 0

    @grid_heuristic = {}
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

  def update_vertex(node)
    is_in_queue = @queue.has_key?(node.position)
    if get_g_value(node.position) != get_rhs(node.position) && is_in_queue
      @queue[node.position] = calculate_key(node)
    elsif get_g_value(node.position) != get_rhs(node.position) && !is_in_queue
      @queue.push node.position, calculate_key(node)
    elsif get_g_value(node.position) == get_rhs(node.position) && is_in_queue
      @queue.delete(node.position)
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
      u, k_old = @queue.min
      u_node = Node.new(u[0], u[1])
      k_new = calculate_key(u_node)
      if first_less_than_second(k_old, k_new)
        @queue[u] = k_new
      elsif get_g_value(u) > get_rhs(u)
        @g_values[u] = get_rhs(u)
        @queue.delete(u)
        # Considerando predecessores = sucessores
        Observation.instance.all_directions.each do |dir|
          s = u_node.child(dir)
          if s
            rhs_s = get_rhs(s.position)
            g_u   = get_g_value(u)
            cost  = Observation.instance.direction_cost(dir)
            @rhs[s.position] = [rhs_s, g_u + cost].min if !s.equals?(goal)
            update_vertex(s)
          end
        end
      else
        g_old = get_g_value(u)
        @g_values[u] = nil
        # Considerando predecessores = sucessores
        Observation.instance.all_directions.each do |dir|
          s = u_node.child(dir)
          if s
            rhs_s = get_rhs(s.position)
            cost  = Observation.instance.direction_cost(dir)
            if (rhs_s == cost + g_old) && !s.equals?(goal)
              new_rhs = 1.0/0.0
              Observation.instance.all_directions.each do |direction|
                s_line = s.child(direction)
                if s_line
                  n_cost = Observation.instance.direction_cost(direction)
                  n_g    = get_g_value(s_line.position)
                  if new_rhs > n_cost + n_g
                    new_rhs = n_cost + n_g
                  end
                end
              end
              @rhs[s.position] = new_rhs
            end
            update_vertex(s)
          end
        end
        # Mesmo procedimento acima, agora para u
        rhs_s = get_rhs(u)
        cost  = 0
        if (rhs_s == cost + g_old) && !u_node.equals?(goal)
          new_rhs = 1.0/0.0
          Observation.instance.all_directions.each do |direction|
            s_line = u_node.child(direction)
            if s_line
              n_cost = Observation.instance.direction_cost(direction)
              n_g    = get_g_value(s_line.position)
              if new_rhs > n_cost + n_g
                new_rhs = n_cost + n_g
              end
            end
          end
          @rhs[u] = new_rhs
        end
        update_vertex(u_node)
      end
    end

    @test = []
    @rhs.each_pair do |k, v|
      @test << [Node.new(k[0], k[1]), v]
    end
  end

  #
  # Compute the h-value. This value is the Chebyshev  distance
  # from certain state to the goal state, or a value previously defined.
  #
  def h_value(current, goal)
    if @grid_heuristic[current.position].nil?
      [(goal.i - current.i).abs, (goal.j - current.j).abs].max
    else
      @grid_heuristic[current.position]
    end
  end

  def get_move(current_node, final_node)
    compute_shortest_path(final_node) if @first_run

    changed = []
    Observation.instance.all_directions.each do |dir|
      child = current_node.any_child(dir)
      g = Observation.instance.grid[child.i][child.j]
      if g != @grid[child.i][child.j] && g != '.'
        #changed << [current_node, dir]
        changed.concat child.predecessors
      end
      @grid[child.i][child.j] = g
    end
    puts "======================"
    puts changed

    changed = [] if @first_run
    @first_run = false

    if !changed.empty?
      @km = @km + h_value(@last, @start)
      @last = @start

      cands = []
      @changed = []
      changed.each do |node_tuple|
        node      = node_tuple[0]
        direction = node_tuple[1]
        old_cost  = Observation.instance.direction_cost(direction)
        candidate = node.any_child(direction)
        #cands << candidate
        @changed << [node, 0]
        if get_rhs(node.position) == get_g_value(candidate.position) + old_cost
          new_rhs = 1.0/0.0
          Observation.instance.all_directions.each do |dir|
            s_line = node.child(dir)
            if s_line
              n_cost = Observation.instance.direction_cost(dir)
              n_g    = get_g_value(s_line.position)
              if new_rhs > n_cost + n_g
                new_rhs = n_cost + n_g
              end
            end
          end
          @rhs[node.position] = new_rhs
        end
        update_vertex(node)
      end
      #cands.each do |c|
      #  @rhs[c.position] = nil
      #  @g_values[c.position] = nil
      #  @queue.delete(c.position)
      #end
      compute_shortest_path(final_node)
    end

    ##conferir
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

    return new_node, @test
  end
end
