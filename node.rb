require "./observation.rb"
require "singleton"

class Node
  attr_accessor :i, :j, :value, :parent, :depth

  def initialize(i, j, parent=nil)
    @i = i
    @j = j
    @parent = parent
    @value = 0
  end

  def any_child(direction)
    case direction
    when "North"
      return Node.new(i-1, j, self) if Observation.instance.is_valid?(i-1, j)
    when "South"
      return Node.new(i+1, j, self) if Observation.instance.is_valid?(i+1, j)
    when "East"
      return Node.new(i, j+1, self) if Observation.instance.is_valid?(i, j+1)
    when "West"
      return Node.new(i, j-1, self) if Observation.instance.is_valid?(i, j-1)
    when "Northeast"
      return Node.new(i-1, j+1, self) if Observation.instance.is_valid?(i-1, j+1) && Observation.instance.is_valid?(i, j+1) && Observation.instance.is_valid?(i-1, j)
    when "Northwest"
      return Node.new(i-1, j-1, self) if Observation.instance.is_valid?(i-1, j-1) && Observation.instance.is_valid?(i-1, j) && Observation.instance.is_valid?(i, j-1)
    when "Southeast"
      return Node.new(i+1, j+1, self) if Observation.instance.is_valid?(i+1, j+1) && Observation.instance.is_valid?(i+1, j) && Observation.instance.is_valid?(i, j+1)
    when "Southwest"
      return Node.new(i+1, j-1, self) if Observation.instance.is_valid?(i+1, j-1) && Observation.instance.is_valid?(i+1, j) && Observation.instance.is_valid?(i, j-1)
    end

    return nil
  end

  def child(direction)
    case direction
    when "North"
      return Node.new(i-1, j, self) if Observation.instance.is_valid_and_passable?(i-1, j)
    when "South"
      return Node.new(i+1, j, self) if Observation.instance.is_valid_and_passable?(i+1, j)
    when "East"
      return Node.new(i, j+1, self) if Observation.instance.is_valid_and_passable?(i, j+1)
    when "West"
      return Node.new(i, j-1, self) if Observation.instance.is_valid_and_passable?(i, j-1)
    when "Northeast"
      return Node.new(i-1, j+1, self) if Observation.instance.is_valid_and_passable?(i-1, j+1) && Observation.instance.is_valid_and_passable?(i, j+1) && Observation.instance.is_valid_and_passable?(i-1, j)
    when "Northwest"
      return Node.new(i-1, j-1, self) if Observation.instance.is_valid_and_passable?(i-1, j-1) && Observation.instance.is_valid_and_passable?(i-1, j) && Observation.instance.is_valid_and_passable?(i, j-1)
    when "Southeast"
      return Node.new(i+1, j+1, self) if Observation.instance.is_valid_and_passable?(i+1, j+1) && Observation.instance.is_valid_and_passable?(i+1, j) && Observation.instance.is_valid_and_passable?(i, j+1)
    when "Southwest"
      return Node.new(i+1, j-1, self) if Observation.instance.is_valid_and_passable?(i+1, j-1) && Observation.instance.is_valid_and_passable?(i+1, j) && Observation.instance.is_valid_and_passable?(i, j-1)
    end

    return nil
  end

  def children
    ch = []
    Observation.instance.all_directions.each do |direction|
      ch << child(direction)
    end
    ch.compact
  end

  def equals?(node)
    if self.i == node.i && self.j == node.j
      return true
    end
    return false
  end

  def position
    return [self.i, self.j]
  end

  def is_neighbour?(node)
    if (self.i - node.i).abs > 1 || (self.j - node.j).abs > 1
      return false
    end
    return true
  end
end
