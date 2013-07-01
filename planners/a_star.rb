require "./node.rb"
require "./pqueue.rb"

include Math

class AStar

  def initialize
    @path = []
  end

  def get_move(current_node, goal)
    if @path.empty?
      a_star_result = a_star(current_node, goal)
      x = a_star_result[:node]
      while x != nil
        @path << x
        x = x.parent
      end
      @path.pop
    end
    return @path.pop
  end

  private

  def a_star(initial_node, final_node)
    num_expanded = 0
    x = Node.new(initial_node.i, initial_node.j)
    x.depth = 0
    x.value = 0.0
    return {:node => x, :num_expanded => num_expanded} if x.position == final_node.position

    frontier = nil
    frontier = PQueue.new{|a, b| dist(a, final_node).to_f + a.value < dist(b, final_node).to_f + b.value}
    frontier.push(x)

    explored = {}
    frontier_hash = {}
    frontier_hash[x.position] = true

    loop do
      return nil if frontier.empty?
      current_node = frontier.pop
      frontier_hash[current_node.position] = false
      return {:node => current_node, :num_expanded => num_expanded} if current_node.position == final_node.position
      explored[current_node.position] = true
      num_expanded += 1
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
    end
  end

  #
  # Distancia de Chebyshev entre dois pontos específicos
  #
  def dist(current, goal)
    dy = (goal.i - current.i).abs.to_f
    dx = (goal.j - current.j).abs.to_f

    return 0
    #if dx > dy
    #  return 1.41421*dy + 1.0*(dx-dy)
    #else
    #  return 1.41421*dx + 1.0*(dy-dx)
    #end
  end
end
