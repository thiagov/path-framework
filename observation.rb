require "singleton"
require "./map.rb"

#
#
# NOTA: nossos metodos recebem parametros da forma (linha, coluna),
# ou seja i = height e j = width!
#
class Observation
  include Singleton

  def initialize
  end

  attr_accessor :grid

  def set_fields
    @visibility = 2

    @grid_width = Map.instance.grid_width
    @grid_height = Map.instance.grid_height
    @type = Map.instance.type

    @grid = []
    @grid_height.times do |h|
      @grid[h] = []
      @grid_width.times do |w|
        @grid[h][w] = " "
      end
    end
  end

  def grid_height
    @grid_height
  end

  def grid_width
    @grid_width
  end

  def update_observation(i, j)
    x = j
    y = i

    l_x = x - @visibility
    h_x = x + @visibility
    l_y = y - @visibility
    h_y = y + @visibility

    (l_x..h_x).each do |h|
      (l_y..h_y).each do |w|
        if is_valid?(w, h)
          @grid[w][h] = Map.instance.grid[w][h]
        end
      end
    end
  end

  #TODO: alterar caso mudemos para pesos maiores que 1
  def weight(i, j)
    return 1
  end

  def is_observed(i, j)
    if @grid[i][j] == " "
      return false
    end
    return true
  end

  def is_passable?(i, j)
    if @grid[i][j] == "." || @grid[i][j] == "S" || @grid[i][j] == " "
      return true
    else
      return false
    end
  end

  def is_valid?(i, j)
    return false if i >= @grid_height || i < 0 || j < 0 || j >= @grid_width
    return true
  end

  def is_valid_and_passable?(i, j)
    return true if is_valid?(i, j) && is_passable?(i, j)
    return false
  end

  def print_grid(initial_node, goal, current_node = nil, special_spaces=[])
    @grid_height.times do |h|
      @grid_width.times do |w|
        is_special = false
        special_spaces.each do |node|
          if node.i == h && node.j == w
            is_special = true
            break
          end
        end

        if is_special
          print "|"
        elsif current_node && current_node.i == h && current_node.j == w
          print "X"
        elsif initial_node && initial_node.i == h && initial_node.j == w
          print "I"
        elsif goal && goal.i == h && goal.j == w
          print "G"
        else
          print "#{@grid[h][w]}"
        end
      end
      puts "\n"
    end
  end

  def view_all_map
    @grid_height.times do |h|
      @grid_width.times do |w|
        @grid[h][w] = Map.instance.grid[h][w]
      end
    end
  end

  def all_directions
    if @type == "octile"
      ["North", "South", "East", "West", "Northeast", "Northwest", "Southeast", "Southwest"]
    else
      ["North", "South", "East", "West"]
    end
  end

  def direction_cost(direction)
    case direction
    when "North", "South", "East", "West"
      return 1.0
    when "Northeast", "Northwest", "Southeast", "Southwest"
      return 1.41421
    end
  end

  def corridor_directions(direction)
    if @type == "octile"
      case direction
      when "North"
        return ["Northeast", "North", "Northwest"]
      when "South"
        return ["Southeast", "South", "Southwest"]
      when"East"
        return ["Northeast", "East", "Southeast"]
      when "West"
        return ["Northwest", "West", "Southwest"]
      when "Northeast"
        return ["East", "Northeast", "North"]
      when "Northwest"
        return ["West", "Northwest", "North"]
      when "Southeast"
        return ["South", "Southeast", "East"]
      when "Southwest"
        return ["West", "Southwest", "South"]
      end
    else
      case direction
      when "North"
        return ["North", "East", "West"]
      when "South"
        return ["South", "East", "West"]
      when"East"
        return ["North", "South", "East"]
      when "West"
        return ["North", "South", "West"]
      end
    end
  end

  def special_corridor_directions(direction, init_dir)
    if @type == "octile"
      case init_dir
      when "North"
        ban = ["South", "Southeast", "Southwest"]
      when "South"
        ban = ["North", "Northeast", "Northwest"]
      when "East"
        ban = ["West", "Southwest", "Northwest"]
      when "West"
        ban = ["East", "Southeast", "Southwest"]
      when "Northeast"
        ban = ["Southwest", "South", "West"]
      when "Northwest"
        ban = ["Southeast", "South", "East"]
      when "Southeast"
        ban = ["Northwest", "North", "West"]
      when "Southwest"
        ban = ["Northeast", "North", "East"]
      end

      case direction
      when "North"
        return ["Northeast", "North", "Northwest"] - ban
      when "South"
        return ["Southeast", "South", "Southwest"] - ban
      when"East"
        return ["Northeast", "East", "Southeast"] - ban
      when "West"
        return ["Northwest", "West", "Southwest"] - ban
      when "Northeast"
        return ["East", "Northeast", "North"] - ban
      when "Northwest"
        return ["West", "Northwest", "North"] - ban
      when "Southeast"
        return ["South", "Southeast", "East"] - ban
      when "Southwest"
        return ["West", "Southwest", "South"] - ban
      end
    else
      case init_dir
      when "North"
        ban = ["South"]
      when "South"
        ban = ["North"]
      when "East"
        ban = ["West"]
      when "West"
        ban = ["East"]
      end

      case direction
      when "North"
        return ["North", "East", "West"] - ban
      when "South"
        return ["South", "East", "West"] - ban
      when"East"
        return ["North", "South", "East"] - ban
      when "West"
        return ["North", "South", "West"] - ban
      end
    end
  end



  def is_valid_direction?(direction, i, j)
    case direction
    when "North"
      return true if Observation.instance.is_valid_and_passable?(i-1, j)
    when "South"
      return true if Observation.instance.is_valid_and_passable?(i+1, j)
    when"East"
      return true if Observation.instance.is_valid_and_passable?(i, j+1)
    when "West"
      return true if Observation.instance.is_valid_and_passable?(i, j-1)
    when "Northeast"
      return Node.new(i-1, j+1, self) if Observation.instance.is_valid_and_passable?(i-1, j+1) && Observation.instance.is_valid_and_passable?(i, j+1) && Observation.instance.is_valid_and_passable?(i-1, j)
    when "Northwest"
      return true if Observation.instance.is_valid_and_passable?(i-1, j-1) && Observation.instance.is_valid_and_passable?(i-1, j) && Observation.instance.is_valid_and_passable?(i, j-1)
    when "Southeast"
      return true if Observation.instance.is_valid_and_passable?(i+1, j+1) && Observation.instance.is_valid_and_passable?(i+1, j) && Observation.instance.is_valid_and_passable?(i, j+1)
    when "Southwest"
      return true if Observation.instance.is_valid_and_passable?(i+1, j-1) && Observation.instance.is_valid_and_passable?(i+1, j) && Observation.instance.is_valid_and_passable?(i, j-1)
    end
    return false
  end

end
