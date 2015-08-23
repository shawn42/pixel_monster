module Prefab
  include Gosu
  COLORS = [Color::AQUA,Color::BLUE,Color::CYAN,Color::FUCHSIA,Color::GRAY,Color::GREEN,Color::RED,Color::WHITE,Color::YELLOW]

  def self.test_level(entity_manager:,x:,y:,map:)
    tile_width = 32
    map.tiles.each do |c,ys|
      ys.each do |r,color|
        tile(entity_manager: entity_manager, 
                    x: c * tile_width+16, y: r*tile_width+16, color: Color::GRAY)
        color_source(entity_manager: entity_manager, 
                    x: c * tile_width+16, y: r*tile_width+16, color: color )

      end
    end

    monster_exit(entity_manager: entity_manager, 
                x: map.exit_x*tile_width+16, 
                y: map.exit_y*tile_width+16, 
                color: map.exit_color )

    monster(entity_manager: entity_manager, x: x + 3 * tile_width, y: y-16-14-100, color: Color::GRAY)
  end

  def self.monster_exit(entity_manager:,x:,y:,color:)
      entity_manager.add_entity JoyColor.new(color), Position.new(x, y), Boxed.new(14,14)
  end

  def self.color_source(entity_manager:,x:,y:,color:)
      entity_manager.add_entity ColorSource.new, JoyColor.new(color), Position.new(x, y), Boxed.new(14,14)
  end

  def self.tile(entity_manager:,x:,y:,color:)
    entity_manager.add_entity JoyColor.new(color), Boxed.new(16, 16), Position.new(x, y)
  end

  def self.monster(entity_manager:,x:,y:,color:)
    entity_manager.add_entity Monster.new, JoyColor.new(color), Boxed.new(14, 14),
      Position.new(x, y), Velocity.new
  end

end

