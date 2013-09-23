require "./node.rb"
require "./pqueue.rb"

include Math

class AStar

  def initialize
    @path = []
  end

  def get_move(current_node, goal)
    expanded_states  = 0
    planning_episode = false

    if @path.empty?
      planning_episode = true

      a_star_result = a_star(current_node, goal)

      expanded_states = a_star_result[:num_expanded]

      x = a_star_result[:node]
      while x != nil
        @path << x
        x = x.parent
      end
      @path.pop
    end
    return @path.pop, nil, {:planning_episode => planning_episode, :expanded_states => expanded_states}
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
    return [(goal.i - current.i).abs, (goal.j - current.j).abs].max
    #return 0
  end
end
