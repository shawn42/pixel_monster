require_relative 'monster_system'
require_relative 'particle_emitter_system'
require_relative 'particles_system'
require_relative 'rainbow_system'
require_relative 'fading_system'
require_relative 'camera_system'
require_relative 'timer_system'
require_relative 'timed_level_system'
require_relative 'timed_system'
require_relative 'input_mapping_system'
require_relative 'sound_system'
require_relative 'background_system'
require_relative 'render_system'
require_relative 'editor_system'

CMYK = Struct.new(:c,:m,:y,:k,:a)

class ColorMix
  def self.to_cymk(color)
    cyan    = 255 - color.red
    magenta = 255 - color.green
    yellow  = 255 - color.blue
    black   = [cyan, magenta, yellow].min
    cyan    = ((cyan - black) / (255 - black))
    magenta = ((magenta - black) / (255 - black))
    yellow  = ((yellow  - black) / (255 - black))

    CMYK.new cyan, magenta, yellow, black/255, color.alpha
  end

  def self.to_rgba(color)
    r = color.c * (1.0 - color.k) + color.k
    g = color.m * (1.0 - color.k) + color.k
    b = color.y * (1.0 - color.k) + color.k
    r = ((1.0 - r) * 255.0 + 0.5).round
    g = ((1.0 - g) * 255.0 + 0.5).round
    b = ((1.0 - b) * 255.0 + 0.5).round

    Gosu::Color.rgba(r,g,b,color.a)
  end

  def self.mix(color1, color2)
    c = 0
    m = 0
    y = 0
    k = 0
    a = 0
    colors = [ColorMix.to_cymk(color1),
      ColorMix.to_cymk(color2)]

    colors.each do |color|
      c += color.c
      m += color.m
      y += color.y
      k += color.k
      a += color.a
    end
    c = c/colors.size.to_f
    m = m/colors.size.to_f
    y = y/colors.size.to_f
    k = k/colors.size.to_f
    a = a/colors.size.to_f
    color = CMYK.new c, m, y, k, a
    ColorMix.to_rgba(color)
  end
end
