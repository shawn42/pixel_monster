class Level
  attr_accessor :map, :complete
  def self.load(filename)
    Level.new
  end

  def map
    Map.new
  end

  def complete!
    @complete = true
  end

  def complete?
    @complete
  end

  def reset!
    @complete = false
  end
end

class Map
  # TODO do these need to be anything other than just T/F
  TILE_SIZE = 32
  attr_accessor :tiles, :exit_x, :exit_y, :exit_color
  def initialize
    @exit_x = 14
    @exit_y = 21
    @exit_color = Gosu::Color::YELLOW
    @tiles = Hash.new{|h,k|h[k] = {}}
    10.times do |i|
      @tiles[i][24] = Gosu::Color::BLUE
    end

    10.times do |i|
      @tiles[20+i][24] = Gosu::Color::RED
    end

    80.times do |i|
      @tiles[i-10][26] = Gosu::Color::YELLOW
    end
  end

  def blocked?(world_x, world_y)
    @tiles[world_x / TILE_SIZE][world_y / TILE_SIZE]
  end

  def in_exit?(world_x, world_y)
    x = world_x / TILE_SIZE
    y = world_y / TILE_SIZE
    x == @exit_x && y == @exit_y
  end
end

