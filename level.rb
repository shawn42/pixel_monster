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
  attr_accessor :complete, :last_ms_to_complete, :best_ms_to_complete
  attr_writer :map

  def self.load(file_name:, number:, high_scores: )
    level = Level.new
    map = level.map
    level.best_ms_to_complete = high_scores.best(number: number)
    png = Gosu::Image.new File.join('levels', file_name)
    load_level_meta(level, png)

    colors = []
    png.width.times do |c|
      (png.height-1).times do |r|
        # v = png[c,r+1]
        gosu_color = png.get_pixel(c,r+1)

        # unless v == 0
        unless gosu_color.alpha == 0

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

  def self.color_close_enough?(color, path_color)
    # be forgiving here, because pixel editors suck.
    return (color.red - path_color.red).abs < 4 &&
           (color.green - path_color.green).abs < 4 &&
           (color.blue - path_color.blue).abs < 4 &&
           color.alpha < MAX_ALPHA
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
          color = png.get_pixel(loc.x, loc.y+1)
        end

        if color && !path_locs.include?(loc)
          open_list << loc if color_close_enough? color, path_color
        end
      end

      path_locs << active_node
    end
    path_locs
  end

  def self.load_level_meta(level, png)
    map = level.map
    map.exit_color = png.get_pixel(0,0)#Wgosu_color_from_value png[0,0]

    command = nil
    (1..png.width-1).each do |c|
      a = png.get_pixel(c, 0).alpha
      if command.nil? && a > 0
        command = [png.get_pixel(c,0)]
      elsif command && a == 0
        begin
        process_command(level, command)
        rescue => ex
          puts 'failed to process command'
          puts ex.inspect
        end
        command = nil
      elsif a > 0
        command << png.get_pixel(c, 0)
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

