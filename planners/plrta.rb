# encoding: utf-8

require "./node.rb"
require "priority_queue"

class Plrta

  def initialize
    @grid_heuristic = []
    Observation.instance.grid_height.times do |h|
      @grid_heuristic[h] = []
      Observation.instance.grid_width.times do |w|
        @grid_heuristic[h][w] = nil
      end
    end

    @queue = PriorityQueue.new
    @queue_max_length = 39
    @num_updates = 100

    # Usada somente para imprimir na tela
    @updated = []
  end

  def get_move(current_node, goal)
    @updated = []
    @expanded_states = 0
    planning_episode = true

    # Processo de aprendizado utilizando priority_queue
    state_update(current_node.position, goal)
    cnt = 0
    while cnt < @num_updates && !@queue.empty?
      p = @queue.delete_min[0]
      if p != goal.position && Observation.instance.is_passable?(p[0], p[1])
        state_update(p, goal)
        cnt += 1
      end
    end

    # Seleciona o vizinho com menor f-value
    neighbours = []
    Observation.instance.all_directions.each do |direction|
      ch = current_node.child(direction)
      if ch
        neighbours << {:node => ch, :h => h_value(ch, goal) + Observation.instance.direction_cost(direction)}
      end
    end
    next_node = neighbours.min_by{|el| el[:h]}[:node]

    return next_node, @updated, {:planning_episode => planning_episode, :expanded_states => @expanded_states}
  end

  def state_update(node_pos, goal)
    node = Node.new(node_pos[0], node_pos[1])
    neighbours = []
    Observation.instance.all_directions.each do |direction|
      ch = node.child(direction)
      if ch
        neighbours << {:node => ch, :h => h_value(ch, goal) + Observation.instance.direction_cost(direction)}
      end
    end
    selected = neighbours.min_by{|el| el[:h]}
    delta = selected[:h] - h_value(node, goal)

    @expanded_states += 1

    if delta > 0
      @updated << node
      @grid_heuristic[node.i][node.j] = selected[:h]
      neighbours.each do |el|
        add_to_queue(el[:node], delta)
      end
    end
  end

  # Como o priority queue utilizado sempre ordena em ordem crescente,
  # inserimos os valores como -delta ao invés de delta. Dessa forma
  # a ordenação é invertida.
  def add_to_queue(node, delta)
    node_pos = node.position
    if !@queue.has_key?(node_pos)
      if @queue.length == @queue_max_length
        smallest_delta = @queue.max_by{|x| x[1]}
        if smallest_delta[1] < -delta
          @queue.delete(smallest_delta[0])
          @queue.push node_pos, -delta
        end
      else
        @queue.push node_pos, -delta
      end
    end
  end

  #
  # Compute the h-value. This value is the Chebyshev  distance
  # from certain state to the goal state, or a value previously defined.
  #
  def h_value(current, goal)
    if @grid_heuristic[current.i][current.j].nil?
      [(goal.i - current.i).abs, (goal.j - current.j).abs].max
    else
      @grid_heuristic[current.i][current.j]
    end
  end
end
