# encoding: utf-8

require "./node.rb"

# TODO: o initialize_state nao deveria ser chamado somente quando o estado vai para closed list?
# Time-bounded adaptative A*
# A idéia é a mesma do RTBA*. No entanto, ao recomeçar um A*, o valor do
# f-value ao último nó a ser expandido pelo A* anterior é armazenado. Esse
# valor é utilizado posteriormente para atualizar h-values quando possível, assim
# como no adaptative A*.
class Tbaa
  def initialize(root, final_node)
    @lookahead = 1150

    @search_number = 0
    @search = {}
    @path_cost = {}

    restart_a_star(root, final_node)
    @grid_heuristic = []
    Observation.instance.grid_height.times do |h|
      @grid_heuristic[h] = []
      Observation.instance.grid_width.times do |w|
        @grid_heuristic[h][w] = nil
      end
    end
  end

  # Recomeça o A*. A OPEN list e a CLOSED list são resetadas, e o A* recomeça
  # a partir do estado atual do agente.
  def restart_a_star(current_node, final_node)
    @path = []
    @final_path = []
    @goal_found = nil

    @root = Node.new(current_node.i, current_node.j)
    @root.depth = 0
    @root.value = 0.0

    @open_list = PQueue.new{|a, b| h_value(a, final_node) + a.value < h_value(b, final_node) + b.value}
    @open_list_hash = {}
    @open_list.push(@root)
    @open_list_hash[@root.position] = true

    @closed_list = []
    @closed_list_hash = {}

    @search_number += 1
    initialize_state(@root, final_node)
  end

  # Verifica se é necessário recomeçar o A*.
  def start_new_search?(goal)
    @path.each do |node|
      if !Observation.instance.is_passable?(node.i, node.j)
        best = @open_list.top
        @path_cost[@search_number] = h_value(best, goal) + best.value
        return true 
      end
    end
    return false
  end

  # Atualiza os h-values de certo estado quando possível. A atualização ocorre
  # quando o estado que vai ser usado pelo novo A* já foi expandido por um A*
  # anterior (@search[state] != @search_number) e a condição do adaptative A*
  # é satisfeita.
  def initialize_state(node, goal)
    state = node.position
    if @search[state] && @search[state] != @search_number
      if h_value(node, goal) < @path_cost[@search[state]] - node.value
        @grid_heuristic[node.i][node.j] = @path_cost[@search[state]] - node.value
      end
    end
    @search[state] = @search_number
  end

  def get_move(current_node, goal)
    @expanded_states = 0
    planning_episode = false

    next_node = nil

    restart_a_star(current_node, goal) if start_new_search?(goal)

    if !@goal_found
      planning_episode = true

      x = limited_a_star(goal, @lookahead)
      @goal_found = x if x.position == goal.position
    else
      x = @goal_found
    end

    @path = []
    while x != nil
      @path << x
      x = x.parent
      if !x.nil? && x.position == current_node.position
        next_node = @path.pop
        @final_path << current_node
        break
      end
    end

    if next_node.nil?
      next_node = @final_path.pop
    end

    return next_node, @path, {:planning_episode => planning_episode, :expanded_states => @expanded_states}
  end

  #
  # A* procedure.
  # Returns:
  #   The goal node if it was found, nil if the goal cant be reached
  #   or the last expanded node if the lookahead goes down to 0.
  #
  def limited_a_star(final_node, lookahead)
    loop do
      return nil if @open_list.empty?
      current_node = @open_list.pop
      @open_list_hash[current_node.position] = false
      return current_node if current_node.position == final_node.position
      @closed_list_hash[current_node.position] = true
      @closed_list << current_node
      @expanded_states += 1
      lookahead -= 1

      Observation.instance.all_directions.each do |direction|
        child = current_node.child(direction)
        if child
          child.depth = child.parent.depth + 1
          child.value = child.parent.value + Observation.instance.direction_cost(direction)
          initialize_state(child, final_node)
          if !@open_list_hash[child.position] && !@closed_list_hash[child.position]
            @open_list.push(child)
            @open_list_hash[child.position] = true
          end
        end
      end
      return current_node if lookahead == 0
    end
  end

  #
  # Compute the h-value for the A* procedure. This value is the Chebyshev  distance
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
