require 'chunky_png'

class Level
  attr_accessor :map, :complete
  def self.load(filename)
    level = Level.new
    map = level.map

    png = ChunkyPNG::Image.from_file filename
    map.exit_color = gosu_color_from_value png[0,0]

    colors = []
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
          # elsif gosu_color == Gosu::Color::BLUE
          #   colors << Gosu::Color.rgba(0, 0xC2, 0x39, 255)
          #   map.tiles[c][r+1] = gosu_color
          else
            colors << gosu_color
            map.tiles[c][r+1] = gosu_color
          end
        end
      end
    end

    avg_red = colors.collect(&:red).sum / colors.size.to_f
    avg_green = colors.collect(&:green).sum / colors.size.to_f
    avg_blue = colors.collect(&:blue).sum / colors.size.to_f
    map.average_color = Gosu::Color.rgba(avg_red, avg_green, avg_blue, 255)

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
    :player_x, :player_y, :average_color
  def initialize
    @tiles = Hash.new{|h,k|h[k] = {}}
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

