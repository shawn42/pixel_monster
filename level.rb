class Level
  attr_accessor :map
  def self.load(filename)
    Level.new
  end

  def map
    Map.new
  end
end

class Map
  # TODO do these need to be anything other than just T/F
  TILE_SIZE = 32
  attr_accessor :tiles
  def initialize
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
end

