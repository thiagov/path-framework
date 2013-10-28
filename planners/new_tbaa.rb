# encoding: utf-8

require "./node.rb"
require "priority_queue/ruby_priority_queue"

class Tbaa
  def initialize(root, final_node, lookahead)
    @lookahead = lookahead > 0 ? lookahead : 1150

    @search_number = 0
    @search = {}
    @path_cost = {}

    @grid_heuristic = []
    Observation.instance.grid_height.times do |h|
      @grid_heuristic[h] = []
      Observation.instance.grid_width.times do |w|
        @grid_heuristic[h][w] = nil
      end
    end

    @g_values = []
    Observation.instance.grid_height.times do |h|
      @g_values[h] = []
      Observation.instance.grid_width.times do |w|
        @g_values[h][w] = 1.0/0.0
      end
    end

    initialize_search(root, final_node)
  end

  def restart(root, final_node)
    @g_values = []
    Observation.instance.grid_height.times do |h|
      @g_values[h] = []
      Observation.instance.grid_width.times do |w|
        @g_values[h][w] = 1.0/0.0
      end
    end
    initialize_search(root, final_node)
  end

  # Atualiza os h-values de certo estado quando necessario. A atualização ocorre
  # quando o estado que vai ser usado pelo novo A* já foi expandido por um A*
  # anterior (@search[state] != @search_number) e a condição do adaptative A*
  # é satisfeita.
  def initialize_state(node, goal)
    state = node.position
    if @search[state].nil?
      @g_values[node.i][node.j] = 1.0/0.0
    elsif @search[state] != @search_number
      if h_value(node, goal) < @path_cost[@search[state]] - @g_values[node.i][node.j]
        @grid_heuristic[node.i][node.j] = @path_cost[@search[state]] - @g_values[node.i][node.j]
      end
      @g_values[node.i][node.j] = 1.0/0.0
    end
    @search[state] = @search_number
  end

  # Recomeça o A*. A OPEN list eh resetadas, e o A* recomeça
  # a partir do estado atual do agente.
  def initialize_search(current_node, final_node)
    @path = []
    @final_path = []
    @search_number += 1

    @root = Node.new(current_node.i, current_node.j)
    initialize_state(@root, final_node)
    @g_values[@root.i][@root.j] = 0.0

    @open_list = RubyPriorityQueue.new
    @open_list_hash = {}
    @open_list.push @root, h_value(@root, final_node) + @g_values[@root.i][@root.j]
    @open_list_hash[@root.position] = true

    initialize_state(final_node, final_node)
    @goal_found_flag = false
  end

  #
  # Busca utilizando A*.
  #
  def search(final_node)
    expansions = 0
    while !@open_list.empty? && expansions < @lookahead# && (@g_values[final_node.i][final_node.j] + h_value(final_node, final_node)).round(4) > (@g_values[@open_list.min_key.i][@open_list.min_key.j] + h_value(@open_list.min_key, final_node)).round(4)
      break if @open_list.min_key.equals?(final_node)
      current_node = @open_list.delete_min[0]
      @open_list_hash[current_node.position] = false
      Observation.instance.all_directions.each do |direction|
        child = current_node.child(direction)
        if child
          initialize_state(child, final_node)
          if @g_values[child.i][child.j] > @g_values[current_node.i][current_node.j] + Observation.instance.direction_cost(direction)
            @g_values[child.i][child.j] = @g_values[current_node.i][current_node.j] + Observation.instance.direction_cost(direction)
            @open_list.push child, h_value(child, final_node) + @g_values[child.i][child.j]
          end
        end
      end
      expansions += 1
    end
    if @open_list.empty?
      return false
    end
    best = @open_list.min[0]
    if best.position == final_node.position
      @goal_found_flag = true
    end

    @path = []
    x = best
    while x != nil
      @path << x
      x = x.parent
    end

    return true
  end

  # Verifica se é necessário recomeçar o A*.
  def start_new_search?(current_node, goal)
    @path.each do |node|
      if !Observation.instance.is_passable?(node.i, node.j)
        @grid_heuristic[node.i][node.j] = 1.0/0.0
        best = @open_list.min[0]
        @path_cost[@search_number] = h_value(best, goal) + @g_values[best.i][best.j]
        initialize_search(current_node, goal)
        @path = []
      end
    end
  end

  def get_move(current_node, goal)
    start_new_search?(current_node, goal)
    if !@goal_found_flag
      search(goal)
      start_new_search?(current_node, goal)
    end
    if !@path.empty?
      partial = []
      next_node = nil
      @path.each do |node|
        if node.position == current_node.position
          next_node = partial.pop
          @final_path << current_node
          break
        end
        partial << node
      end

      if next_node.nil?
        next_node = @final_path.pop
        if next_node.nil?
          next_node = current_node
        end
      end
    else
      next_node = current_node
    end

    @path_cost[@search_number] = h_value(next_node, goal) + @g_values[next_node.i][next_node.j] if next_node.equals?(goal)

    return next_node, @path, {:planning_episode => true, :expanded_states => 0}
  end

  #
  # Compute the h-value. This value is the Chebyshev  distance
  # from certain state to the goal state.
  #
  def h_value(current, goal)
    if @grid_heuristic[current.i][current.j].nil?
      [(goal.i - current.i).abs, (goal.j - current.j).abs].max
    else
      @grid_heuristic[current.i][current.j]
    end
  end

end
