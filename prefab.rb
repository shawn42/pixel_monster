module Prefab
  include Gosu
  COLORS = [Color::AQUA,Color::BLUE,Color::CYAN,Color::FUCHSIA,Color::GRAY,Color::GREEN,Color::RED,Color::WHITE,Color::YELLOW]

  TILE_WIDTH = 32
  def self.level(entity_manager:,level:)
    # XXX there's gotta be a bettery way to do this
    entity_manager.add_entity level
    map = level.map

    map.tiles.each do |c,ys|
      ys.each do |r,color|
        if color.is_a? Gosu::Color
          tile(entity_manager: entity_manager,
                      x: c * TILE_WIDTH+16, y: r*TILE_WIDTH+16, color: Color::GRAY)

          color_source(entity_manager: entity_manager,
                      x: c * TILE_WIDTH+16, y: r*TILE_WIDTH+16, color: color )
        else
          tile_def = color
          case color
          when BlackHoleTile
            black_hole(entity_manager: entity_manager, tile_def: tile_def,
                        x: c * TILE_WIDTH+16, y: r*TILE_WIDTH+16 )
          when BouncyTile
            map.tiles[c].delete r
            # tile(entity_manager: entity_manager,
            #             x: c * TILE_WIDTH+16, y: r*TILE_WIDTH+16, color: Color::GRAY)
            bouncy_tile(entity_manager: entity_manager, tile_def: tile_def, tile_x: c, tile_y: r, color: Color::GRAY)
          when DeathTile
            death_tile(entity_manager: entity_manager, tile_def: tile_def, x: c * TILE_WIDTH+16, y: r*TILE_WIDTH+16 )
          else
            raise "unkown special tile #{special}"
          end

        end
      end
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
      entity_manager.add_entity ColorSource.new, JoyColor.new(color), Position.new(x, y), Boxed.new(14,14)
  end

  def self.black_hole(entity_manager:,tile_def:,x:,y:)
      subtract_color = tile_def.subtract_color
      entity_manager.add_entity BlackHole.new, Position.new(x, y), Boxed.new(14,14), JoyColor.new(Gosu::Color.rgba(30,30,30,255)), ColorSink.new(subtract_color)
  end
  def self.bouncy_tile(entity_manager:,tile_def:, tile_x:,tile_y:, color:)
      x = tile_x * TILE_WIDTH + 16
      y = tile_y * TILE_WIDTH + 16
      eid = entity_manager.add_entity Bouncy.new, Position.new(x, y), Boxed.new(16,16), JoyColor.new(color)

      path = tile_def.path
      start = vec(tile_x,tile_y)
      entity_manager.add_component( id:eid, component: MovableTile.new(path:path, start_node: start, dir_vec: Vec::RIGHT) ) if path
      eid
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
