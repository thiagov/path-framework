# encoding: utf-8

require "./node.rb"

# Time-bounded A*
# Esse algoritmo encontra caminhos em ambientes completamente observaveis.
# A idéia é rodar um A* com profundidade limitada. A cada iteração o A* expande
# mais nós, até que alcance o estado objetivo. Enquanto issoo agente se move
# na direção mais promissora do A* corrente a cada iteração.
class Tba

  def initialize(root, final_node)
    @lookahead = 100

    @root = Node.new(root.i, root.j)
    @root.depth = 0
    @root.value = 0.0

    @closed_list = []
    @closed_list_hash = {}

    @open_list = PQueue.new{|a, b| h_value(a, final_node) + a.value < h_value(b, final_node) + b.value}
    @open_list_hash = {}
    @open_list.push(@root)
    @open_list_hash[@root.position] = true

    @path = []
    @goal_found = nil
  end

  def get_move(current_node, goal)
    next_node = nil

    if !@goal_found
      x = limited_a_star(goal, @lookahead)
      @goal_found = x if x.position == goal.position
    else
      x = @goal_found
    end
    path = []
    while x != nil
      path << x
      x = x.parent
      if !x.nil? && x.position == current_node.position
        next_node = path.pop
        @path << current_node
        break
      end
    end

    if next_node.nil?
      next_node = @path.pop
    end

    return next_node
  end

  #
  # A* procedure.
  # Returns:
  #   The goal node if it was found, nil if the goal cant be reached
  #   or the last expanded node if the lookahead goes down to 0.
  #
  def limited_a_star(final_node, lookahead)
    num_expanded = 0
    loop do
      return nil if @open_list.empty?
      current_node = @open_list.pop
      @open_list_hash[current_node.position] = false
      return current_node if current_node.position == final_node.position
      @closed_list_hash[current_node.position] = true
      @closed_list << current_node
      num_expanded += 1
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
