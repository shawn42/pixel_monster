module Prefab
  include Gosu
  COLORS = [Color::AQUA,Color::BLUE,Color::CYAN,Color::FUCHSIA,Color::GRAY,Color::GREEN,Color::RED,Color::WHITE,Color::YELLOW]

  TILE_WIDTH = 32
  def self.camera(entity_store:, x:, y:, scale:)
    entity_store.add_entity Camera.new(scale: scale, x: x, y: y)
  end

  def self.level(entity_store:,level:)
    # XXX there's gotta be a better way to do this
    entity_store.add_entity level
    map = level.map

    to_delete = []
    map.tiles.each do |c,ys|
      ys.each do |r,color|
        eid = nil
        tile_def = color

        case tile_def
        when ColorSourceTile
          eid = color_source(entity_store: entity_store,
                      x: c * TILE_WIDTH+16, y: r*TILE_WIDTH+16, color: tile_def.marker_color )
        when BlackHoleTile
          eid = black_hole(entity_store: entity_store, tile_def: tile_def,
                      x: c * TILE_WIDTH+16, y: r*TILE_WIDTH+16 )
        when BouncyTile
          eid = bouncy_tile(entity_store: entity_store, tile_def: tile_def, tile_x: c, tile_y: r, color: Color::GRAY)
        when DeathTile
          eid = death_tile(entity_store: entity_store, tile_def: tile_def, x: c * TILE_WIDTH+16, y: r*TILE_WIDTH+16 )
        when RainbowTile
          eid = rainbow_tile(entity_store: entity_store, tile_def: tile_def, x: c * TILE_WIDTH+16, y: r*TILE_WIDTH+16 )
        when BrightTile
          eid = bright_tile(entity_store: entity_store, tile_def: tile_def, x: c * TILE_WIDTH+16, y: r*TILE_WIDTH+16 )
        when EmptyTile
          eid = tile(entity_store: entity_store, x: c * TILE_WIDTH+16, y: r*TILE_WIDTH+16, color: Gosu::Color::GRAY )
        else
          raise "unkown special tile #{special}"
        end


        if eid && tile_def.path
          to_delete << vec(c,r)
          map.tiles[c].delete r
          path = tile_def.path
          start = vec(c,r)
          entity_store.add_component( id:eid, component: MovableTile.new(path:path, start_node: start, dir_vec: Vec::RIGHT) )
        end

      end
    end
    to_delete.each do |v|
      map.tiles[v.x].delete v.y
    end

    monster_exit(entity_store: entity_store, color: map.exit_color,
                x: map.exit_x*TILE_WIDTH+16,
                y: map.exit_y*TILE_WIDTH+16)


    monster(entity_store: entity_store, color: Color::BLACK,
            x: map.player_x * TILE_WIDTH+16,
            y: map.player_y * TILE_WIDTH+16)

    entity_store.add_entity LevelTimer.new, Timed.new, Label.new(size: 35), Position.new(500, 40, 99)

    best_ms = level.best_ms_to_complete
    best = best_ms ? (best_ms/1000).round(1) : "?"
    entity_store.add_entity Label.new(size: 16, text: "(#{best})"), Position.new(510, 80, 99)

  end

  def self.monster_exit(entity_store:,x:,y:,color:)
      entity_store.add_entity Exit.new, JoyColor.new(color), Position.new(x, y), Boxed.new(14,14)
      entity_store.add_entity Exit.new, JoyColor.new(Color::BLACK), Position.new(x, y), Boxed.new(8,8)


      # TODO how to pause game while this is happening?
#       zoom = ZoomCameraOperation.new(scale: 3, target_x: x, target_y: y, duration: 400)
#       entity_store.add_entity Timer.new(:zoom_exit, 500, false, zoom)
#
#       unzoom = ZoomCameraOperation.new(scale: 0, target_x: x, target_y: y, duration: 300)
#       entity_store.add_entity Timer.new(:unzoom_exit, 1000, false, unzoom)
  end

  def self.color_source(entity_store:,x:,y:,color:)
      # TODO add border on Boxed?
      entity_store.add_entity ColorSource.new, JoyColor.new(color), Position.new(x, y), Boxed.new(16,16)
  end

  RAINBOW_CHANGE_TIME_MS = 500
  def self.rainbow_tile(entity_store:,tile_def:,x:,y:)
    entity_store.add_entity Rainbow.new(colors: tile_def.colors), Position.new(x,y), Boxed.new(16,16), JoyColor.new(tile_def.colors.first), ColorSource.new, Timer.new("colorchange", RAINBOW_CHANGE_TIME_MS, true, ChangeColorEvent)
  end

  def self.bright_tile(entity_store:,tile_def:,x:,y:)
    entity_store.add_entity SuperColorSource.new, Position.new(x,y), Boxed.new(16,16), JoyColor.new(tile_def.color), Border.new(16,16)
  end

  def self.black_hole(entity_store:,tile_def:,x:,y:)
      subtract_color = tile_def.subtract_color
      entity_store.add_entity BlackHole.new, Position.new(x, y), Boxed.new(14,14), JoyColor.new(Gosu::Color.rgba(30,30,30,255)), ColorSink.new(subtract_color)
  end
  def self.bouncy_tile(entity_store:,tile_def:, tile_x:,tile_y:, color:)
      x = tile_x * TILE_WIDTH + 16
      y = tile_y * TILE_WIDTH + 16
      entity_store.add_entity Bouncy.new, Position.new(x, y), Boxed.new(16,16), JoyColor.new(color)
  end
  def self.death_tile(entity_store:,tile_def:,x:,y:)
    entity_store.add_entity Death.new, Position.new(x, y), Boxed.new(16,16)
  end

  def self.tile(entity_store:,x:,y:,color:)
    entity_store.add_entity JoyColor.new(color), Boxed.new(16, 16), Position.new(x, y)
  end

  def self.monster(entity_store:,x:,y:,color:)

    entity_store.add_entity Monster.new, JoyColor.new(color), Boxed.new(13, 13),
      Position.new(x, y), Velocity.new, PlatformPosition.new, Debug.new

  end

end
