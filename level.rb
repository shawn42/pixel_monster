require 'chunky_png'
require_relative 'vec'
require_relative 'tiles'
require_relative 'movable_tile_path'
require_relative 'map'

RELATIVE_DIR_MAP = {
  Vec::UP => {
    Vec::LEFT  => Vec::LEFT,
    Vec::UP    => Vec::UP,
    Vec::RIGHT => Vec::RIGHT,
    Vec::DOWN  => Vec::DOWN,
  },
  Vec::RIGHT => {
    Vec::LEFT  => Vec::UP,
    Vec::UP    => Vec::RIGHT,
    Vec::RIGHT => Vec::DOWN,
    Vec::DOWN  => Vec::LEFT,
  },
  Vec::DOWN => {
    Vec::LEFT  => Vec::RIGHT,
    Vec::UP    => Vec::DOWN,
    Vec::RIGHT => Vec::LEFT,
    Vec::DOWN  => Vec::UP,
  },
  Vec::LEFT => {
    Vec::LEFT  => Vec::DOWN,
    Vec::UP    => Vec::LEFT,
    Vec::RIGHT => Vec::UP,
    Vec::DOWN  => Vec::RIGHT,
  },
}

LEFT_HANDED_SEARCH = [ Vec::LEFT, Vec::UP, Vec::RIGHT, Vec::DOWN ]

class Level
  START_COLOR = Gosu::Color::WHITE
  EXIT_COLOR = Gosu::Color::BLACK
  MAX_ALPHA = 255
  attr_accessor :map, :complete, :last_ms_to_complete, :best_ms_to_complete
  def self.load(file_name:, number:, high_scores: )
    level = Level.new
    map = level.map
    level.best_ms_to_complete = high_scores.best(number: number)

    png = ChunkyPNG::Image.from_file File.join('levels',file_name)
    load_level_meta(level, png)

    colors = []
    png.width.times do |c|
      (png.height-1).times do |r|
        v = png[c,r+1]
        unless v == 0
          gosu_color = gosu_color_from_value v

          if gosu_color.alpha == MAX_ALPHA
            special_color = gosu_color.abgr
            special = map.special_tile_defs[special_color]
            if gosu_color == START_COLOR
              map.player_x = c
              map.player_y = r
            elsif gosu_color == EXIT_COLOR
              map.exit_x = c
              map.exit_y = r
            else
              tile = special ? special.dup : ColorSourceTile.from_color(gosu_color)
              map.tiles[c][r] = tile

              start_loc = vec(c,r)
              path_locs = find_path_locs(png, start_loc, gosu_color)
              if path_locs.size > 1
                tile.path = MovableTilePath.build(path_locs, start_loc, LEFT_HANDED_SEARCH)
              end
              colors << gosu_color unless special
            end
          end
        end
      end
    end

    if colors.size > 0
      avg_red = colors.collect(&:red).sum / colors.size.to_f
      avg_green = colors.collect(&:green).sum / colors.size.to_f
      avg_blue = colors.collect(&:blue).sum / colors.size.to_f
      map.average_color = Gosu::Color.rgba(avg_red, avg_green, avg_blue, 255)
    else
      map.average_color = map.exit_color
    end

    level
  end

  def self.find_path_locs(png, start_loc, path_color)
    path_locs = []
    open_list = [start_loc]

    until open_list.empty?
      active_node = open_list.pop
      Vec::NEIGHBOR_VECS.map do |n_vec|
        loc = active_node + n_vec
        color = nil
        if (0...32).include?(loc.x) and (0...32).include?(loc.y)
          color = gosu_color_from_value png[loc.x,loc.y+1]
        end

        if color && !path_locs.include?(loc)
          # puts "red: #{color.red} vs #{path_color.red}"
          # puts "green: #{color.green} vs #{path_color.green}"
          # puts "blue: #{color.blue} vs #{path_color.blue}"
          # puts "alpha: #{color.alpha}"
          if color.red == path_color.red &&
            color.green == path_color.green &&
            color.blue == path_color.blue &&
            color.alpha < MAX_ALPHA
            open_list << loc
          end
        end
      end

      path_locs << active_node
    end
    path_locs
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
        begin
        process_command(level, command)
        rescue Exception => ex
          puts 'failed to process command'
          puts ex.inspect
        end
        command = nil
      elsif a > 0
        command << gosu_color_from_value(png[c,0])
      end
    end
  end

  COLOR_TO_TILE_KLASS = {
    Gosu::Color::BLACK => BlackHoleTile,
    Gosu::Color::YELLOW => RainbowTile,
    Gosu::Color::GREEN => BrightTile,
    Gosu::Color::BLUE => BouncyTile,
    Gosu::Color::RED => DeathTile,
    Gosu::Color::GRAY => EmptyTile,
  }

  def self.process_command(level, command)
    map = level.map

    klass = COLOR_TO_TILE_KLASS[command[0]]
    if klass
      tile = klass.from_colors command
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

  def complete!(ms_to_complete:)
    @last_ms_to_complete = ms_to_complete
    @complete = true
  end

  def skip!
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

