class Tile
  attr_accessor :marker_color, :path
  def blocking?; true; end
end

class ColorSourceTile < Tile
  def self.from_color(color)
    self.new.tap do |t|
      t.marker_color = color
    end
  end
end

class SpecialTile < Tile
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

class GhostTile < SpecialTile
  attr_accessor :color
  def self.from_colors(colors)
    self.new.tap do |t|
      t.marker_color = colors[1]
      t.color = colors[2]
    end
  end
  def blocking?; false; end
end

class BrightTile < SpecialTile
  attr_accessor :color
  def self.from_colors(colors)
    self.new.tap do |t|
      t.marker_color = colors[1]
      t.color = colors[2]
    end
  end
end

class RainbowTile < SpecialTile
  attr_accessor :colors
  def self.from_colors(colors)
    self.new.tap do |t|
      t.marker_color = colors[1]
      t.colors = colors[2..-1]
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
class EmptyTile < SpecialTile
  def self.from_colors(colors)
    self.new.tap do |t|
      t.marker_color = colors[1]
    end
  end
end

