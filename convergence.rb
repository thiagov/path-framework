#encoding: utf-8
require "./node.rb"
require "./planners/a_star.rb"
require "./planners/lrta.rb"
require "./planners/lsslrta.rb"
require "./planners/prta.rb"
#require "./planners/extended_prta.rb"
#require "./planners/mcts_lrta.rb"
#require "./planners/flat_mc.rb"
#require "./planners/flrta.rb"
require "./planners/rtaa.rb"
require "./planners/tba.rb"
require "./planners/rtba.rb"
require "./planners/new_tbaa.rb"
require "./planners/plrta.rb"
require "./planners/lrta_k.rb"
require "./planners/d_lite_simple.rb"
require "pp"

include Math

def same_path?(previous, current)
  prev = previous.map{|p| [p.i, p.j]}
  curr = current.map{|c| [c.i, c.j]}
  prev == curr
end

# Get info from stdin
init_i     = ARGV[0].to_i
init_j     = ARGV[1].to_i
end_i      = ARGV[2].to_i
end_j      = ARGV[3].to_i
map_name   = ARGV[4]
algorithm  = ARGV[5]
lookahead  = ARGV[6].to_i
queue_size = ARGV[7].to_i

# Initialize map and observation
Map.instance.read_map(map_name)
Observation.instance.set_fields
#Observation.instance.view_all_map #Uncomment this line to have full observability

# Initialize start and goal nodes
initial_node = Node.new(init_i, init_j)
goal = Node.new(end_i, end_j)


# Set planner
planner = nil
case algorithm
# A* needs full observability to work!
when "a_star"
  planner = AStar.new
when "lrta"
  planner = Lrta.new
when "prta"
  planner = Prta.new(initial_node)
when "lsslrta"
  planner = LssLrta.new(lookahead)
when "rtaa"
  planner = Rtaa.new(lookahead)
when "extendedprta"
  planner = ExtendedPrta.new(initial_node)
when "mcts"
  planner = Mcts.new(initial_node)
when "flatmc"
  planner = FlatMC.new(initial_node)
when "tba"
  planner = Tba.new(initial_node, goal, lookahead)
when "rtba"
  planner = Rtba.new(initial_node, goal)
when "tbaa"
  planner = Tbaa.new(initial_node, goal, lookahead)
when "plrta"
  planner = Plrta.new(queue_size, lookahead)
when "lrta_k"
  planner = LrtaK.new(lookahead)
when "d_lite"
  planner = DLite.new(initial_node, goal)
end

# Create some variables for the planning
previous_path         = []
path                  = []
current_node          = initial_node
final_cost = 0

# Insert initial node on path
path << current_node
Observation.instance.update_observation(current_node.i, current_node.j)

# Find path
changed_heuristics = true
num_solves = 0
init_time = Time.now
while (changed_heuristics)
  num_solves += 1
  while !current_node.equals?(goal)
    node_candidate, special, statistics = planner.get_move(current_node, goal)

    if current_node.is_neighbour?(node_candidate) && Map.instance.is_valid?(node_candidate.i, node_candidate.j) && Map.instance.is_passable?(node_candidate.i, node_candidate.j)
      current_node = node_candidate
    else
      puts "Ocorreu um erro! Posição iniválida!"
      exit
    end

    path << current_node
    Observation.instance.update_observation(current_node.i, current_node.j)
  end

  # Get path cost
  total_cost = 0.0
  for i in (0..path.size-2)
    node1 = path[i]
    node2 = path[i+1]
    sum = (node1.i - node2.i).abs + (node1.j - node2.j).abs

    if sum%2 == 0
      total_cost += 1.41421
    else
      total_cost += 1.0
    end
  end
  final_cost = total_cost

  # Updates changed_heuristics
  if previous_path != [] && same_path?(previous_path, path)
    changed_heuristics = false
  else
    planner.restart(initial_node, goal)
    previous_path = path
    path = []
    current_node = initial_node
    path << current_node
    Observation.instance.set_fields
    Observation.instance.update_observation(current_node.i, current_node.j)
  end
end
end_time = Time.now

puts "Número de resolvidas: #{num_solves}"
puts "Tempo total: #{end_time - init_time}"
puts "Path cost: #{final_cost}"
