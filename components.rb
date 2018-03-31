class DyingEvent; end
class Debug; end
class BackgroundBlob; end
class Monster; end
class ColorSource; end
class SuperColorSource; end
class Bouncy; end
class BlackHole; end
class Death; end
class Particle; end

class EmitParticlesEvent
  attr_accessor :color, :target, :intensity, :speed, :size
  def initialize(color:, target:nil, intensity: 25, speed: nil, size: nil)
    @color = color
    @target = target
    @intensity = intensity
    @speed = speed
    @size = size
  end
end

class ChangeColorEvent; end
class Rainbow
  attr_accessor :colors, :color_index
  def initialize(colors:)
    @colors = colors
    @color_index = 0
  end
end

class MovableTile
  attr_accessor :path, :vel, :world_target, :dir_vec, :path_target
  def initialize(path:, start_node:, dir_vec:)
    @path = path
    @vel = vec(0,0)
    @path_target = start_node
    @dir_vec = dir_vec
  end
end

class Exit
  attr_accessor :open
  def initialize(open:false)
    @open = open
  end
end
class EntityTarget
  attr_accessor :id
  def initialize(id)
    @id = id
  end
end

class PlatformPosition
  attr_accessor :last_grounded_at, :last_tile_bouncy,
    :jump_time, :last_jump

  def initialize
    @last_grounded_at = -1
    @last_tile_bouncy = false
    @jump_time = 0
    @last_jump = 0
  end
end

class Camera
  attr_accessor :x, :y, :scale, :target_x, :target_y
  def initialize(x:,y:,scale:1)
    @x = x
    @y = y
    @target_x = @x
    @target_y = @y
    @scale = scale
  end
end
class ZoomCameraOperation
  attr_accessor :scale, :duration, :ttl, :target_scale, :target_x, :target_y
  def initialize(scale:, duration:, target_x:, target_y:)
    @scale = 0
    @duration = duration
    @ttl = duration
    @target_scale = scale
    @target_x = target_x
    @target_y = target_y
  end
end

class Position
  attr_accessor :x, :y, :z
  def initialize(x,y,z=2)
    @x = x
    @y = y
    @z = z
  end

  def to_vec
    vec(@x, @y)
  end

  def nearby(dx,dy)
    Position.new @x + rand(dx*2) - dx,
      @y + rand(dy*2) - dy, @z
  end
end

class Velocity < Vec
end

class JoyColor
  attr_accessor :color
  def initialize(color)
    @color = color
  end
end
class ColorSink < JoyColor; end

class Boxed
  attr_accessor :width, :height, 
    :squished_y_at, :squish_height, :squish_y_amount, :squish_y_dir,
    :squished_x_at, :squish_width, :squish_x_amount, :squish_x_dir
  def initialize(width,height)
    @width = width
    @height = height

    @squish_height = 0
    @squish_y_amount = 0
    @squish_y_dir = 0

    @squish_width = 0
    @squish_x_amount = 0
    @squish_x_dir = 0
  end
end

class Border
  attr_accessor :width, :height
  def initialize(width,height)
    @width = width
    @height = height
  end
end

class JoyImage
  attr_reader :name, :image
  def initialize(name)
    @name = name
    @image = Gosu::Image.new name
  end
end

class LevelTimer; end
class Timed
  attr_accessor :accumulated_time_in_ms

  def initialize
    @accumulated_time_in_ms = 0
  end
end

class Label
  attr_accessor :text, :size, :font
  def initialize(size:,text:"",font:nil)
    @size = size
    @font = font
    @text = text
  end
end

class Timer
  attr_accessor :ttl, :repeat, :total, :event, :name, :expires_at
  def initialize(name, ttl, repeat, event = nil)
    @name = name
    @total = ttl
    @ttl = ttl
    @repeat = repeat
    @event = event
  end
end

class SoundEffectEvent
  attr_accessor :sound_to_play
  def initialize(sound_to_play)
    @sound_to_play = sound_to_play
  end
end
