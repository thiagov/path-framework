#encoding: utf-8
require "./node.rb"
require "./planners/a_star.rb"
require "./planners/lrta.rb"
require "./planners/lsslrta.rb"
require "./planners/prta.rb"
require "./planners/extended_prta.rb"
require "./planners/mcts_lrta.rb"
require "./planners/flat_mc.rb"
require "pp"
require "gosu"

include Math

# Get info from stdin
init_i   = ARGV[0].to_i
init_j   = ARGV[1].to_i
end_i    = ARGV[2].to_i
end_j    = ARGV[3].to_i
map_name = ARGV[4]
algorithm = ARGV[5]

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
  planner = LssLrta.new
when "extendedprta"
  planner = ExtendedPrta.new(initial_node)
when "mcts"
  planner = Mcts.new(initial_node)
when "flatmc"
  planner = FlatMC.new(initial_node)
end

# Initialize window
class GameWindow < Gosu::Window
  def initialize(algorithm, initial_node, goal, planner)
    @one_time = true
    @offset = 20

    super Map.instance.grid_width*@offset, Map.instance.grid_height*@offset, false
    self.caption = "#{algorithm}"

    @aqua    = Gosu::Color.new(0xff00ffff)
    @green   = Gosu::Color.new(0xff00ff00)
    @gray    = Gosu::Color.new(0xff808080)
    @red     = Gosu::Color.new(0xffff0000)
    @yellow  = Gosu::Color.new(0xffffff00)
    @fuchsia = Gosu::Color.new(0xffff00ff)
    @black   = Gosu::Color.new(0xff000000)

    # Create some variables for the planning
    @planner          = planner
    @initial_node     = initial_node
    @goal             = goal
    @medium_exec_time = 0.0
    @longest_time     = 0.0
    @cnt              = 0
    @path             = []
    @current_node     = initial_node

    # Insert initial node on path
    @path << @current_node
    Observation.instance.update_observation(@current_node.i, @current_node.j)

    @font = Gosu::Font.new(self, Gosu::default_font_name, 12)
  end

  def update
    @fps = Gosu::fps()

    if button_down? Gosu::KbEscape
      close
    end
    if !@current_node.equals?(@goal)
      start_time = Time.now

      node_candidate = @planner.get_move(@current_node, @goal)

      end_time          = Time.now
      @cnt              += 1
      move_time         = (end_time - start_time)
      @medium_exec_time += move_time
      @longest_time      = move_time if move_time > @longest_time

      if @current_node.is_neighbour?(node_candidate) && Map.instance.is_valid?(node_candidate.i, node_candidate.j) && Map.instance.is_passable?(node_candidate.i, node_candidate.j)
        @current_node = node_candidate
      else
        puts "Ocorreu um erro! Posição iniválida!"
        exit
      end

      @path << @current_node
      Observation.instance.update_observation(@current_node.i, @current_node.j)
    elsif @one_time
      @one_time = false
      # Get path cost
      total_cost = 0.0
      for i in (0..@path.size-2)
        node1 = @path[i]
        node2 = @path[i+1]
        sum = (node1.i - node2.i).abs + (node1.j - node2.j).abs

        if sum%2 == 0
          total_cost += 1.41421
        else
          total_cost += 1.0
        end
      end
      # Print output
      puts "#{total_cost} #{@medium_exec_time/@cnt.to_f} #{@longest_time}"
    end
  end

  def draw
    @font.draw("FPS: #{@fps}", 10, 10, 2, 1.0, 1.0, 0xffffff00)
    Map.instance.grid_height.times do |h|
      Map.instance.grid_width.times do |w|
        if @current_node && @current_node.i == h && @current_node.j == w
          draw_quad(w*@offset, h*@offset, @red, w*@offset+@offset, h*@offset, @red, w*@offset, h*@offset + @offset, @red, w*@offset+@offset, h*@offset+@offset, @red, 1)
        elsif @initial_node && @initial_node.i == h && @initial_node.j == w
          draw_quad(w*@offset, h*@offset, @yellow, w*@offset+@offset, h*@offset, @yellow, w*@offset, h*@offset + @offset, @yellow, w*@offset+@offset, h*@offset+@offset, @yellow, 1)
        elsif @goal && @goal.i == h && @goal.j == w
          draw_quad(w*@offset, h*@offset, @yellow, w*@offset+@offset, h*@offset, @yellow, w*@offset, h*@offset + @offset, @yellow, w*@offset+@offset, h*@offset+@offset, @yellow, 1)
        elsif Map.instance.grid[h][w] == "."
          draw_quad(w*@offset, h*@offset, @gray, w*@offset+@offset, h*@offset, @gray, w*@offset, h*@offset + @offset, @gray, w*@offset+@offset, h*@offset+@offset, @gray, 1)
        elsif Map.instance.grid[h][w] == "S"
          draw_quad(w*@offset, h*@offset, @aqua, w*@offset+@offset, h*@offset, @aqua, w*@offset, h*@offset + @offset, @aqua, w*@offset+@offset, h*@offset+@offset, @aqua, 1)
        elsif Map.instance.grid[h][w] == "T"
          draw_quad(w*@offset, h*@offset, @green, w*@offset+@offset, h*@offset, @green, w*@offset, h*@offset + @offset, @green, w*@offset+@offset, h*@offset+@offset, @green, 1)
        elsif Map.instance.grid[h][w] == "@"
          draw_quad(w*@offset, h*@offset, @black, w*@offset+@offset, h*@offset, @black, w*@offset, h*@offset + @offset, @black, w*@offset+@offset, h*@offset+@offset, @black, 1)
        else
          draw_quad(w*@offset, h*@offset, @fuchsia, w*@offset+@offset, h*@offset, @fuchsia, w*@offset, h*@offset + @offset, @fuchsia, w*@offset+@offset, h*@offset+@offset, @fuchsia, 1)
        end
      end
    end
  end
end

window = GameWindow.new(algorithm, initial_node, goal, planner)
window.show
