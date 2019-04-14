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
    vec(tile_x*TILE_SIZE+TILE_SIZE/2, tile_y*TILE_SIZE+TILE_SIZE/2)
  end

  def world_to_map(world_x, world_y)
    vec(world_x.round/TILE_SIZE, world_y.round/TILE_SIZE)
  end

  def blocked?(world_x, world_y)
    tile = @tiles[world_x / TILE_SIZE][world_y / TILE_SIZE]
    tile && tile.blocking?
  end
  alias at blocked?

  def in_exit?(world_x, world_y)
    x = world_x / TILE_SIZE
    y = world_y / TILE_SIZE
    x == @exit_x && y == @exit_y
  end
end
