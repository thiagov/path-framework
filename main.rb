require "./node.rb"
require "./planners/a_star.rb"
require "./planners/lrta.rb"
require "pp"

include Math

# Get info from stdin
init_i   = ARGV[0].to_i
init_j   = ARGV[1].to_i
end_i    = ARGV[2].to_i
end_j    = ARGV[3].to_i
map_name = ARGV[4]
algorithm = ARGV[5]

# Initialize map
Map.instance.read_map(map_name)
#Map.instance.print_map

# Initialize observation
Observation.instance.set_fields
#Uncomment this line to have full observability
#Observation.instance.view_all_map

initial_node = Node.new(init_i, init_j)
goal = Node.new(end_i, end_j)

current_node = initial_node

# Set planner
planner = nil

case algorithm
# A* needs full observability to work!
when "a_star"
  planner = AStar.new
when "lrta"
  planner = Lrta.new
end

medium_exec_time = 0.0
longest_time = 0.0
cnt = 0
path = []

path << current_node
Observation.instance.update_observation(current_node.i, current_node.j)

# Find path
while !current_node.equals?(goal)
  start_time = Time.now

  current_node = planner.get_move(current_node, goal)

  end_time = Time.now
  cnt += 1

  move_time = (end_time - start_time)
  medium_exec_time += move_time
  longest_time = move_time if move_time > longest_time

  path << current_node
  Observation.instance.update_observation(current_node.i, current_node.j)
#  Observation.instance.print_grid(initial_node, goal, current_node)
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

#Observation.instance.print_grid(current_node, goal, nil, path)
puts "#{total_cost} #{medium_exec_time/cnt.to_f} #{longest_time}"
