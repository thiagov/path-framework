require "singleton"

#
#
# NOTA: nossos metodos recebem parametros da forma (linha, coluna),
# ou seja i = height e j = width!
#
class Map
  include Singleton

  @@shallow_water_weight = 1
  @@normal_weight = 1

  attr_accessor :grid, :grid_width, :grid_height, :type

  def initialize
  end

  # Inicializa mapa pelo arquivo de entrada
  def read_map(map_name)
    @grid = []
    File.open("maps/#{map_name}", "r") do |infile|
      @type        = infile.gets.split(" ")[1]
      @grid_height = infile.gets.split(" ")[1].to_i
      @grid_width  = infile.gets.split(" ")[1].to_i
      infile.gets

      while line = infile.gets
        line = line.delete("\n")
        row = []
        line.each_char do |letter|
          row.push(letter)
        end
        @grid.push(row)
      end
    end
  end

  def weight(i, j)
    if @grid[i][j] == "."
      return @@normal_weight
    elsif @grid[i][j] == "S"
      return @@shallow_water_weight
    end
  end

  def is_passable?(i, j)
    if @grid[i][j] == "." || @grid[i][j] == "S"
      return true
    else
      return false
    end
  end

  def is_valid?(i, j)
    return false if i >= @grid_height || i < 0 || j < 0 || j >= @grid_width
    return true
  end

  def print_map
    @grid.each do |row|
      row.each do |el|
        print el
      end
      print "\n"
    end
  end

  def all_directions
    if @type == "octile"
      ["North", "South", "East", "West", "Northeast", "Northwest", "Southeast", "Southwest"]
    else
      ["North", "South", "East", "West"]
    end
  end
end
