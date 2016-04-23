require 'chunky_png'
class SpecialTile
  attr_accessor :marker_color, :path
end

class BlackHoleTile < SpecialTile
  attr_accessor :subtract_color
  def self.from_colors(colors)
    self.new.tap do |t|
      t.marker_color = colors[1]
      t.subtract_color = colors[2] || Gosu::Color::WHITE
    end
  end
end
class BouncyTile < SpecialTile
  def self.from_colors(colors)
    self.new.tap do |t|
      t.marker_color = colors[1]
    end
  end
end
class DeathTile < SpecialTile
  def self.from_colors(colors)
    self.new.tap do |t|
      t.marker_color = colors[1]
    end
  end
end
class Path
  def initialize
    @links = {}
    @current_node = nil
  end

  def add_link(from_vec, to_vec)
    @current_node ||= from_vec
    @links[from_vec] ||= []
    @links[from_vec] << to_vec

    @links[to_vec] ||= []
    @links[to_vec] << from_vec
  end

  def next_node(from_vec, dir_vec)
    # TODO add in directional stuff here
    @links[@current_node].first
  end
end

class Level
  START_COLOR = Gosu::Color::WHITE
  EXIT_COLOR = Gosu::Color::BLACK
  MAX_ALPHA = 255
  attr_accessor :map, :complete
  def self.load(filename)
    level = Level.new
    map = level.map

    png = ChunkyPNG::Image.from_file filename
    load_level_meta(level, png)

    colors = []
    png.width.times do |c|
      (png.height-1).times do |r|
        v = png[c,r+1]
        unless v == 0
          gosu_color = gosu_color_from_value v

          if gosu_color.alpha == MAX_ALPHA
            special = map.special_tile_defs[gosu_color.abgr]
            if gosu_color == START_COLOR
              map.player_x = c
              map.player_y = r
            elsif gosu_color == EXIT_COLOR
              map.exit_x = c
              map.exit_y = r
            elsif special
              map.tiles[c][r] = special
              special.path = Path.new.tap do |path|
                path.add_link [c,r], [c+1,r]
              end

              # path_seg_found = true
              # while path_seg_found
              # end
              #
              # check for path markers around it
              # add to path
              # attach path to tile somehow
            else
              colors << gosu_color
              map.tiles[c][r] = gosu_color
            end
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

  def self.load_level_meta(level, png)
    map = level.map
    map.exit_color = gosu_color_from_value png[0,0]

    command = nil
    (1..png.width-1).each do |c|
      a = ChunkyPNG::Color.a(png[c,0])
      if command.nil? && a > 0
        command = [gosu_color_from_value(png[c,0])]
      elsif command && a == 0
        process_command(level, command)
        command = nil
      elsif a > 0
        command << gosu_color_from_value(png[c,0])
      end
    end
  end

  def self.process_command(level, command)
    map = level.map

    case command[0]
    when Gosu::Color::BLACK
      tile = BlackHoleTile.from_colors command
      map.special_tile_defs[tile.marker_color.abgr] = tile
    when Gosu::Color::BLUE
      tile = BouncyTile.from_colors command
      map.special_tile_defs[tile.marker_color.abgr] = tile
    when Gosu::Color::RED
      tile = DeathTile.from_colors command
      map.special_tile_defs[tile.marker_color.abgr] = tile
    else
      puts "unknown command #{command}"
    end

  end

  def self.gosu_color_from_value(v)
    Gosu::Color.rgba(
      ChunkyPNG::Color.r(v),
      ChunkyPNG::Color.g(v),
      ChunkyPNG::Color.b(v),
      ChunkyPNG::Color.a(v))
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
  HALF_TILE_SIZE = TILE_SIZE / 2
  attr_accessor :tiles,
    :exit_x, :exit_y, :exit_color,
    :player_x, :player_y, :average_color,
    :special_tile_defs
  def initialize
    @tiles = Hash.new{|h,k|h[k] = {}}
    @special_tile_defs = {}
  end

  def map_to_world(tile_x, tile_y)
    vec(world_x*TILE_SIZE, world_y*TILE_SIZE)
  end

  def world_to_map(world_x, world_y)
    vec(world_x.round/TILE_SIZE, world_y.round/TILE_SIZE)
  end

  def blocked?(world_x, world_y)
    @tiles[world_x / TILE_SIZE][world_y / TILE_SIZE]
  end
  alias at blocked?

  def in_exit?(world_x, world_y)
    x = world_x / TILE_SIZE
    y = world_y / TILE_SIZE
    x == @exit_x && y == @exit_y
  end
end
