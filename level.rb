require 'chunky_png'

class Level
  attr_accessor :map, :complete
  def self.load(filename)
    level = Level.new
    map = level.map

    png = ChunkyPNG::Image.from_file filename
    map.exit_color = gosu_color_from_value png[0,0]

    png.width.times do |c|
      (png.height-1).times do |r|
        v = png[c,r+1]
        unless v == 0
          gosu_color = gosu_color_from_value v
          if gosu_color == Gosu::Color::WHITE
            map.player_x = c
            map.player_y = r+1
          elsif gosu_color == Gosu::Color::BLACK
            map.exit_x = c
            map.exit_y = r+1
          else
            map.tiles[c][r+1] = gosu_color
          end
        end
      end
    end

    level
  end

  def self.gosu_color_from_value(v)
    Gosu::Color.rgba(
      ChunkyPNG::Color.r(v),
      ChunkyPNG::Color.g(v),
      ChunkyPNG::Color.b(v),
      255)
  end

  def map
    @map ||= Map.new
  end

  def complete!
    @complete = true
  end

  def complete?
    @complete
  end

  def failed!
    @failed = true
  end

  def failed?
    @failed
  end

  def reset!
    @complete = false
    @failed = false
  end
end

class Map
  # TODO do these need to be anything other than just T/F
  TILE_SIZE = 32
  attr_accessor :tiles, 
    :exit_x, :exit_y, :exit_color,
    :player_x, :player_y
  def initialize
#     @exit_x = 14
#     @exit_y = 21
#     @exit_color = Gosu::Color::YELLOW
    @tiles = Hash.new{|h,k|h[k] = {}}
#     10.times do |i|
#       @tiles[i][24] = Gosu::Color::BLUE
#     end
#
#     10.times do |i|
#       @tiles[20+i][24] = Gosu::Color::RED
#     end
#
#     80.times do |i|
#       @tiles[i-10][26] = Gosu::Color::YELLOW
#     end
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

