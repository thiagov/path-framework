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
require "gosu"

include Math

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
when "flrta"
  planner = Flrta.new(initial_node)
when "plrta"
  planner = Plrta.new(queue_size, lookahead)
when "lrta_k"
  planner = LrtaK.new(lookahead)
when "d_lite"
  planner = DLite.new(initial_node, goal)
end

class GameWindow < Gosu::Window
  def initialize(algorithm, initial_node, goal, planner)
    @one_time = true
    @offset = 20
    @pause = true

    # Initialize windows
    super Map.instance.grid_width*@offset, Map.instance.grid_height*@offset, false, 1000/60
    self.caption = "#{algorithm}"

    # Colors used on map
    @aqua    = Gosu::Color.new(0xff00ffff)
    @green   = Gosu::Color.new(0xff0a6a06)
    @dark_green   = Gosu::Color.new(0x770a6a06)
    @gray    = Gosu::Color.new(0xff808080)
    @dark_gray    = Gosu::Color.new(0x77808080)
    @red     = Gosu::Color.new(0xffff0000)
    @yellow  = Gosu::Color.new(0xffffff00)
    @fuchsia = Gosu::Color.new(0xffff00ff)
    @black   = Gosu::Color.new(0xff000000)
    @orange  = Gosu::Color.new(0xffff7f00)
    @dark_orange  = Gosu::Color.new(0x77ff7f00)

    # Create some variables for the planning
    @planner          = planner
    @initial_node     = initial_node
    @goal             = goal
    @medium_exec_time = 0.0
    @longest_time     = 0.0
    @cnt              = 0
    @path             = []
    @current_node     = initial_node

    # Variable used to additional drawing
    @special = []

    # Insert initial node on path
    @path << @current_node
    Observation.instance.update_observation(@current_node.i, @current_node.j)

    # Font used to display fps
    @font = Gosu::Font.new(self, Gosu::default_font_name, 72)
  end

  def button_down(id)
    @pause = !@pause if id == Gosu::KbP
  end

  def update
    # Get current fps
    @fps = Gosu::fps()

    # Closes window
    if button_down? Gosu::KbEscape
      close
    end

    if !@pause
      # Get agent next action and adds it to the path
      if !@current_node.equals?(@goal)
        start_time = Time.now

        node_candidate, @special = @planner.get_move(@current_node, @goal)
        @special ||= []

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
      # Calculate solution cost ant outputs it
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

      if !@one_time && @current_node.equals?(@goal)
        @one_time = true
        @medium_exec_time = 0.0
        @longest_time     = 0.0
        @cnt              = 0
        @path             = []
        @current_node     = @initial_node
        @path << @current_node
        @planner.restart(@initial_node, @goal)
        Observation.instance.set_fields
        Observation.instance.update_observation(@current_node.i, @current_node.j)
      end
    end
  end

  def draw
    #@font.draw("FPS: #{@fps}", 10, 10, 5, 1.0, 1.0, 0xffffff00)
    Map.instance.grid_height.times do |h|
      Map.instance.grid_width.times do |w|
        is_special = false
        @special.each do |node|
          if node.i == h && node.j == w
            is_special = true
            break
          end
        end
        if is_special
          if Observation.instance.grid[h][w] == " "
            draw_quad(w*@offset, h*@offset, @dark_orange, w*@offset+@offset, h*@offset, @dark_orange, w*@offset, h*@offset + @offset, @dark_orange, w*@offset+@offset, h*@offset+@offset, @dark_orange, 2)
          else
            draw_quad(w*@offset, h*@offset, @orange, w*@offset+@offset, h*@offset, @orange, w*@offset, h*@offset + @offset, @orange, w*@offset+@offset, h*@offset+@offset, @orange, 2)
          end
        end
        if @current_node && @current_node.i == h && @current_node.j == w
          draw_quad(w*@offset, h*@offset, @red, w*@offset+@offset, h*@offset, @red, w*@offset, h*@offset + @offset, @red, w*@offset+@offset, h*@offset+@offset, @red, 3)
        elsif @initial_node && @initial_node.i == h && @initial_node.j == w
          draw_quad(w*@offset, h*@offset, @yellow, w*@offset+@offset, h*@offset, @yellow, w*@offset, h*@offset + @offset, @yellow, w*@offset+@offset, h*@offset+@offset, @yellow, 3)
        elsif @goal && @goal.i == h && @goal.j == w
          draw_quad(w*@offset, h*@offset, @yellow, w*@offset+@offset, h*@offset, @yellow, w*@offset, h*@offset + @offset, @yellow, w*@offset+@offset, h*@offset+@offset, @yellow, 3)
        elsif Map.instance.grid[h][w] == "."
          if Observation.instance.grid[h][w] == " "
            draw_quad(w*@offset, h*@offset, @dark_gray, w*@offset+@offset, h*@offset, @dark_gray, w*@offset, h*@offset + @offset, @dark_gray, w*@offset+@offset, h*@offset+@offset, @dark_gray, 1)
          else
            draw_quad(w*@offset, h*@offset, @gray, w*@offset+@offset, h*@offset, @gray, w*@offset, h*@offset + @offset, @gray, w*@offset+@offset, h*@offset+@offset, @gray, 1)
          end
        elsif Map.instance.grid[h][w] == "S"
          draw_quad(w*@offset, h*@offset, @aqua, w*@offset+@offset, h*@offset, @aqua, w*@offset, h*@offset + @offset, @aqua, w*@offset+@offset, h*@offset+@offset, @aqua, 1)
        elsif Map.instance.grid[h][w] == "T"
          if Observation.instance.grid[h][w] == " "
            draw_quad(w*@offset, h*@offset, @dark_green, w*@offset+@offset, h*@offset, @dark_green, w*@offset, h*@offset + @offset, @dark_green, w*@offset+@offset, h*@offset+@offset, @dark_green, 1)
          else
            draw_quad(w*@offset, h*@offset, @green, w*@offset+@offset, h*@offset, @green, w*@offset, h*@offset + @offset, @green, w*@offset+@offset, h*@offset+@offset, @green, 1)
          end
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
