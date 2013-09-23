# encoding: utf-8

require "./node.rb"

# Restarting Time-bounded A*
# Esse algoritmo é uma adaptação do TBA* para ambientes parcialmente observáveis.
# Sempre que ele encontra um estado não passável pelo qual ele desejava passar, ele
# reinicia o A*.
class Rtba

  def initialize(root, final_node)
    @lookahead = 100
    restart_a_star(root, final_node)
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
  end

  # Verifica se é necessário recomeçar o A*.
  def start_new_search?
    @path.each do |node|
      if !Observation.instance.is_passable?(node.i, node.j)
        return true 
      end
    end
    return false
  end

  def get_move(current_node, goal)
    @expanded_states = 0
    planning_episode = false

    next_node = nil

    restart_a_star(current_node, goal) if start_new_search?

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
    [(goal.i - current.i).abs, (goal.j - current.j).abs].max
  end
end
