module Prefab
  include Gosu
  COLORS = [Color::AQUA,Color::BLUE,Color::CYAN,Color::FUCHSIA,Color::GRAY,Color::GREEN,Color::RED,Color::WHITE,Color::YELLOW]

  TILE_WIDTH = 32
  def self.level(entity_manager:,level:)
    # XXX there's gotta be a better way to do this
    entity_manager.add_entity level
    map = level.map

    to_delete = []
    map.tiles.each do |c,ys|
      ys.each do |r,color|
        eid = nil
        tile_def = color

        case tile_def
        when ColorSourceTile
          eid = color_source(entity_manager: entity_manager,
                      x: c * TILE_WIDTH+16, y: r*TILE_WIDTH+16, color: tile_def.marker_color )
        when BlackHoleTile
          eid = black_hole(entity_manager: entity_manager, tile_def: tile_def,
                      x: c * TILE_WIDTH+16, y: r*TILE_WIDTH+16 )
        when BouncyTile
          eid = bouncy_tile(entity_manager: entity_manager, tile_def: tile_def, tile_x: c, tile_y: r, color: Color::GRAY)
        when DeathTile
          eid = death_tile(entity_manager: entity_manager, tile_def: tile_def, x: c * TILE_WIDTH+16, y: r*TILE_WIDTH+16 )
        when RainbowTile
          eid = rainbow_tile(entity_manager: entity_manager, tile_def: tile_def, x: c * TILE_WIDTH+16, y: r*TILE_WIDTH+16 )
        when BrightTile
          eid = bright_tile(entity_manager: entity_manager, tile_def: tile_def, x: c * TILE_WIDTH+16, y: r*TILE_WIDTH+16 )
        when EmptyTile
          eid = tile(entity_manager: entity_manager, x: c * TILE_WIDTH+16, y: r*TILE_WIDTH+16, color: Gosu::Color::GRAY )
        else
          raise "unkown special tile #{special}"
        end


        if eid && tile_def.path
          to_delete << vec(c,r)
          map.tiles[c].delete r
          path = tile_def.path
          start = vec(c,r)
          entity_manager.add_component( id:eid, component: MovableTile.new(path:path, start_node: start, dir_vec: Vec::RIGHT) )
        end

      end
    end
    to_delete.each do |v|
      map.tiles[v.x].delete v.y
    end

    monster_exit(entity_manager: entity_manager, color: map.exit_color,
                x: map.exit_x*TILE_WIDTH+16,
                y: map.exit_y*TILE_WIDTH+16)


    monster(entity_manager: entity_manager, color: Color::BLACK,
            x: map.player_x * TILE_WIDTH+16,
            y: map.player_y * TILE_WIDTH+16)
  end

  def self.monster_exit(entity_manager:,x:,y:,color:)
      entity_manager.add_entity Exit.new, JoyColor.new(color), Position.new(x, y), Boxed.new(14,14)
      entity_manager.add_entity Exit.new, JoyColor.new(Color::BLACK), Position.new(x, y), Boxed.new(8,8)
  end

  def self.color_source(entity_manager:,x:,y:,color:)
      # TODO add border on Boxed?
      entity_manager.add_entity ColorSource.new, JoyColor.new(color), Position.new(x, y), Boxed.new(16,16)
  end

  RAINBOW_CHANGE_TIME_MS = 500
  def self.rainbow_tile(entity_manager:,tile_def:,x:,y:)
    entity_manager.add_entity Rainbow.new(colors: tile_def.colors), Position.new(x,y), Boxed.new(16,16), JoyColor.new(tile_def.colors.first), ColorSource.new, Timer.new("colorchange", RAINBOW_CHANGE_TIME_MS, true, ChangeColorEvent)
  end

  def self.bright_tile(entity_manager:,tile_def:,x:,y:)
    entity_manager.add_entity SuperColorSource.new, Position.new(x,y), Boxed.new(16,16), JoyColor.new(tile_def.color), Border.new(16,16)
  end

  def self.black_hole(entity_manager:,tile_def:,x:,y:)
      subtract_color = tile_def.subtract_color
      entity_manager.add_entity BlackHole.new, Position.new(x, y), Boxed.new(14,14), JoyColor.new(Gosu::Color.rgba(30,30,30,255)), ColorSink.new(subtract_color)
  end
  def self.bouncy_tile(entity_manager:,tile_def:, tile_x:,tile_y:, color:)
      x = tile_x * TILE_WIDTH + 16
      y = tile_y * TILE_WIDTH + 16
      entity_manager.add_entity Bouncy.new, Position.new(x, y), Boxed.new(16,16), JoyColor.new(color)
  end
  def self.death_tile(entity_manager:,tile_def:,x:,y:)
    entity_manager.add_entity Death.new, Position.new(x, y), Boxed.new(16,16)
  end

  def self.tile(entity_manager:,x:,y:,color:)
    entity_manager.add_entity JoyColor.new(color), Boxed.new(16, 16), Position.new(x, y)
  end

  def self.monster(entity_manager:,x:,y:,color:)
    entity_manager.add_entity Monster.new, JoyColor.new(color), Boxed.new(14, 14),
      Position.new(x, y), Velocity.new, PlatformPosition.new, Debug.new
  end

end
