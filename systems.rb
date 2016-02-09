# terrible vector class  =P
class Array
  def x; at(0) end
  def y; at(1) end
  def z; at(2) end
  def x=(x); self[0] = x end
  def y=(y); self[1] = y end
  def z=(z); self[2] = z end
end
module Gosu
  class Color
    def info
      [red,green,blue,alpha].inspect
    end
  end
end

module Enumerable
  def sum
    size > 0 ? inject(0, &:+) : 0
  end
end

class ParticlesEmitterSystem
  SPEED = (-3..3).to_a
  POSITIONS = (-15..15).to_a
  def update(entity_manager, dt, input)
    entity_manager.each_entity(EmitParticlesEvent, Position) do |rec|
      ent_id = rec.id
      evt, pos = rec.components

      evt.intensity.times do
        entity_manager.add_entity Position.new(pos.x+POSITIONS.sample, pos.y+POSITIONS.sample, 3),
          Particle.new, JoyColor.new(evt.color), 
          Velocity.new(SPEED.sample, SPEED.sample), Boxed.new(rand(3),rand(3)), EntityTarget.new(evt.target)
      end

      # entity_manager.remove_component klass: EmitParticlesEvent, id: ent_id
      entity_manager.remove_entity ent_id
    end
  end
end

class MonsterSystem
  JUMP_FORGIVENESS = 100 #ms
  SQUISH_MAX = 8 #px
  SQUISH_DURATION = 150 #ms
  PEAK_DURATION = SQUISH_DURATION / 4.0 #ms

  MAX_VEL = 15
  MIN_DIST = 44
  MIN_DIST_SQUARED = MIN_DIST * MIN_DIST
  JUMPS = ['jump1.wav','jump2.wav']
  COLLECT = 'collect.wav'
  WIN_SOUND = 'exit.wav'
  WRONG_COLOR = 'wrong_color.wav'

  def update(entity_manager, dt, input)
    level = entity_manager.find(Level).first.get(Level)
    map = level.map

    monster_rec = entity_manager.find(Monster, PlatformPosition, Position, JoyColor, Boxed, Velocity).first
    ent_id = monster_rec.id
    monster, monster_platform, monster_pos, monster_color, boxed, vel = monster_rec.components
    mc = monster_color.color

    if input.pressed?(Gosu::KbTab) || input.pressed?(Gosu::GpButton5)
      level.complete!
    end

    if input.down?(Gosu::KbR) || input.pressed?(Gosu::GpButton4) || monster_pos.y > 1100
      level.failed!
    end

    has_exit_color = has_exit_color?(map, mc)
    exit_recs = entity_manager.find(Exit, Position, JoyColor, Boxed)
    exit_recs.each do |exit_rec|
      ex, exit_pos, exit_color, exit_boxed = exit_rec.components
      open = ex.open
      if has_exit_color && !open
        ex.open = true
        exit_boxed.height += 8
        exit_boxed.width += 8
        exit_pos.y -= 8
      end
      if open && !has_exit_color
        ex.open = false
        exit_boxed.height -= 8
        exit_boxed.width -= 8
        exit_pos.y += 8
      end
    end

    if in_exit?(map, monster_pos, boxed) 
      if has_exit_color
        entity_manager.add_entity SoundEffectEvent.new(WIN_SOUND)
        level.complete!
      else
        # entity_manager.add_entity SoundEffectEvent.new(WRONG_COLOR)
      end
    end

    speed = 70*dt/1000.0
    on_ground = on_ground?(map, monster_pos, boxed)
    if on_ground
      monster_platform.last_grounded_at = input.total_time if on_ground
      should_boost = should_boost?(map, monster_pos, boxed)
      monster_platform.last_tile_bouncy = should_boost
    end

    old_y_vel = vel.y

    vel.y = 0 if on_ground
    lateral_speed = 1.0
    lateral_speed /= 0.5 unless on_ground

    if input.down?(Gosu::KbLeft) || input.down?(Gosu::GpLeft)
      vel.x -= lateral_speed
    elsif input.down?(Gosu::KbRight) || input.down?(Gosu::GpRight)
      vel.x += lateral_speed
    end


    jumping = false
    can_jump = (input.total_time - monster_platform.last_grounded_at) < JUMP_FORGIVENESS
    can_jump &= vel.y <= 2.5
    # (0..15).each do |i|
    #   puts "Gp#{i}" if input.down?(Gosu::const_get("GpButton#{i}"))
    # end

    if (input.pressed?(Gosu::KbUp) || input.pressed?(Gosu::GpButton1)) && can_jump
      jumping = true
      jump_strength = monster_platform.last_tile_bouncy ? 25 : 15 
      vel.y -= jump_strength

      monster_platform.last_tile_bouncy = false
      monster_platform.last_grounded_at = -1
      entity_manager.add_entity SoundEffectEvent.new(JUMPS.sample)
    else
      vel.y += 0.75
    end

    if vel.x > MAX_VEL
      vel.x = MAX_VEL 
    elsif vel.x < -MAX_VEL
      vel.x = -MAX_VEL
    end
    if vel.y > MAX_VEL
      vel.y = MAX_VEL 
    # elsif vel.y < -MAX_VEL
    #   puts "-MAX: #{vel.y}"
    #   vel.y = -MAX_VEL
    end

    x_step = vel.x < 0 ? -1 : 1
    w = boxed.width
    h = boxed.height
    vel.x.round.abs.times do
      new_x = (monster_pos.x + x_step) % (1024-16)
      if map.blocked?(new_x-w, monster_pos.y-h) ||
        map.blocked?(new_x+w, monster_pos.y-h) ||
        map.blocked?(new_x-w, monster_pos.y+h) ||
        map.blocked?(new_x+w, monster_pos.y+h)
        vel.x = 0
        break
      else
        monster_pos.x = new_x
      end
    end

    y_hit = nil
    y_step = vel.y < 0 ? -1 : 1
    vel.y.round.abs.times do
      new_y = monster_pos.y + y_step
      if map.blocked?(monster_pos.x-w, new_y-h) ||
        map.blocked?(monster_pos.x+w, new_y-h) ||
        map.blocked?(monster_pos.x-w, new_y+h) ||
        map.blocked?(monster_pos.x+w, new_y+h)
        vel.y = 0
        y_hit = vel.y
        break
      else
        monster_pos.y = new_y
      end
    end

    if on_ground
      vel.x *= 0.9
    else
      vel.x *= 0.7
    end

    if jumping
      boxed.squished_at = input.total_time
      boxed.squish_height = ((-36/MAX_VEL.to_f)*SQUISH_MAX)#.floor
      boxed.squish_dir = old_y_vel > 0 ? 1 : -1
    end

    if (y_hit && old_y_vel.abs > 0)
      entity_manager.add_entity SoundEffectEvent.new(COLLECT) # TODO new sound for hitting?
      boxed.squished_at = input.total_time
      boxed.squish_height = (([old_y_vel.abs,6].max/MAX_VEL.to_f)*SQUISH_MAX)#.floor
      boxed.squish_dir = old_y_vel > 0 ? 1 : -1
    end

    if boxed.squished_at
      squish_dt = input.total_time - boxed.squished_at
      if squish_dt < SQUISH_DURATION
        if squish_dt < PEAK_DURATION
          boxed.squish_amount = (boxed.squish_height * (squish_dt/PEAK_DURATION))#.floor
        else
          boxed.squish_amount = (boxed.squish_height * (1.0-(squish_dt-PEAK_DURATION)/(SQUISH_DURATION - PEAK_DURATION)))#.floor
        end
      else
        boxed.squished_at = nil
        boxed.squish_amount = 0
        boxed.squish_amount = 0
        boxed.squish_dir = 0
      end
    end



    # ColorStuffSystem
    dead_ents = nil

    entity_manager.each_entity(ColorSource, Position, JoyColor) do |rec|
      src_id = rec.id
      src, pos, source_color = rec.components
      sc = source_color.color

      x_off = pos.x - monster_pos.x
      y_off = pos.y - monster_pos.y
      dist = x_off*x_off+y_off*y_off

      if dist < MIN_DIST_SQUARED
        blended_color = blend_colors(base: mc, absorbed: sc, weight: 0.15)
        monster_color.color = blended_color
        
        # TODO can I remove while iterating?!?!?
        dead_ents ||= []
        dead_ents << src_id
        # entity_manager.remove_entity src_id
        entity_manager.add_entity pos, EmitParticlesEvent.new(color: sc, target: monster_rec.id)
        entity_manager.add_entity SoundEffectEvent.new(COLLECT)
      end
    end


    # BlackHoleSystem
    entity_manager.each_entity(BlackHole, Position, JoyColor, ColorSink) do |rec|
      black_hole_id = rec.id
      black_hole, pos, black_hole_color, subtract_color = rec.components

      x_off = pos.x - monster_pos.x
      y_off = pos.y - monster_pos.y
      dist = x_off*x_off+y_off*y_off
      if dist < MIN_DIST_SQUARED

        if would_subtract?(base: monster_color.color, subtracted: subtract_color.color)

          entity_manager.add_entity monster_pos, EmitParticlesEvent.new(color: subtract_color.color, target: black_hole_id, intensity: 100)
          # black_hole_color.color = mc

          monster_color.color = subtract_colors(base: monster_color.color, subtracted: subtract_color.color)
          entity_manager.add_entity SoundEffectEvent.new(COLLECT)
        end
      end
      # entity_manager.add_entity pos.nearby(32,32), EmitParticlesEvent.new(color:Prefab::COLORS.sample , target: black_hole_id, intensity: 1)
      if rand(3) == 0
        entity_manager.add_entity pos.nearby(32,32), EmitParticlesEvent.new(color:subtract_color.color, target: black_hole_id, intensity: 1)
      end

      # black_hole_color.color = blend_colors(base: black_hole_color.color, absorbed: Gosu::Color::BLACK, weight: 0.05)
      # cool hair do for player
      # entity_manager.add_entity monster_pos, EmitParticlesEvent.new(color:Prefab::COLORS.sample , target: black_hole_id, intensity: 3)

    end

    # DeathSystem
    entity_manager.each_entity(Death, Position, Boxed) do |rec|
      death_id = rec.id
      death, pos, death_box = rec.components

      x_off = pos.x - monster_pos.x
      y_off = pos.y - monster_pos.y
      dist = x_off*x_off+y_off*y_off
      level.failed! if dist < MIN_DIST_SQUARED && boxes_touch?(pos, death_box, monster_pos, boxed)
    end

    if dead_ents
      dead_ents.each do |dead_id|
        entity_manager.remove_entity dead_id
      end
    end
  end

  def boxes_touch?(a_pos, a_box, b_pos, b_box)
    ((a_pos.x - b_pos.x).abs * 2 <= (a_box.width*2 + b_box.width*2+2)) &&
           ((a_pos.y - b_pos.y).abs * 2 <= (a_box.height*2 + b_box.height*2+2))
  end

  def has_exit_color?(map, color)
    allowed_diff = 20
    map_c = map.exit_color
    ((color.red-map_c.red).abs +
    (color.green-map_c.green).abs +
    (color.blue-map_c.blue).abs)/3.0 < allowed_diff 
  end

  def in_exit?(map, pos, box)
    x = pos.x
    y = pos.y
    w = box.width
    h = box.height

    map.in_exit?(pos.x-w, pos.y+h) || map.in_exit?(pos.x+w, pos.y+h)
  end

  def on_ground?(map, pos, box)
    x = pos.x
    y = pos.y
    w = box.width
    h = box.height

    map.blocked?(pos.x-w, pos.y+h+1) || map.blocked?(pos.x+w, pos.y+h+1)
  end

  def should_boost?(map, pos, box)
    x = pos.x
    y = pos.y
    w = box.width
    h = box.height
    left_tile = map.at(pos.x-w, pos.y+h+1)
    right_tile = map.at(pos.x+w, pos.y+h+1)
    (left_tile && left_tile.is_a?(BouncyTile)) || (right_tile && right_tile.is_a?(BouncyTile))
  end

  def reflectance(absorbtionRatio)
		1.0 + absorbtionRatio - Math.sqrt(absorbtionRatio * absorbtionRatio + (2.0 * absorbtionRatio))
  end

  def subtract_colors(base: , subtracted:)
    Gosu::Color.rgba(
      base.red-subtracted.red,
      base.green-subtracted.green,
      base.blue-subtracted.blue,
      base.alpha)
  end

  def would_subtract?(base: , subtracted:)
    (subtracted.red > 0 && base.red > 0) ||
    (subtracted.green > 0 && base.green > 0) ||
    (subtracted.blue > 0 && base.blue > 0)
  end

  def blend_colors(base: , absorbed: , weight:)
    # return ColorMix.mix(base, absorbed)

    # ORGINAL:
    red = base.red + (absorbed.red - base.red)*weight
    green = base.green + (absorbed.green - base.green)*weight
    blue = base.blue + (absorbed.blue - base.blue)*weight

    # red = (base.red * 0.875 + absorbed.red * 0.125
    # green = base.green * 0.875 + absorbed.green * 0.125
    # blue = base.blue * 0.875 + absorbed.blue * 0.125

    # red = base.red + absorbed.red * weight
    # green = base.green + absorbed.green * weight
    # blue = base.blue + absorbed.blue * weight

    # max = [red,green,blue].max.to_f
    # red = (red / max * 255).round
    # green = (green / max * 255).round
    # blue = (blue / max * 255).round

    Gosu::Color.rgba(red, green, blue, base.alpha)
  end
end
class ParticlesSystem
  def update(entity_manager, dt, input)
    dead_ents = nil
    entity_manager.each_entity(Velocity, Particle, Position, JoyColor, EntityTarget) do |rec|
      ent_id = rec.id
      vel, particle, pos, color, ent_target = rec.components

      scalar = dt/100.0
      pos.x += vel.x * scalar
      pos.y += vel.y * scalar

      target = entity_manager.find_by_id(ent_target.id, Position)
      require 'pry'
      binding.pry if target.nil?
      target_pos = target.get(Position)

      dx = (target_pos.x - pos.x) * scalar / 40
      dy = (target_pos.y - pos.y) * scalar / 40
      vel.x += dx
      vel.y += dy
      
      c = color.color
      color.color = Gosu::Color.rgba(c.red,c.green,c.blue,c.alpha-20*scalar)
      if color.color.alpha <= 0
        dead_ents ||= []
        dead_ents << ent_id 
      end
    end

    entity_manager.remove_entites dead_ents if dead_ents

  end
end

class TimerSystem
  def update(entity_manager, delta, input)
    current_time_ms = input.total_time
    entity_manager.each_entity Timer do |rec|
      timer = rec.get(Timer)
      ent_id = rec.id

      if timer.expires_at
        if timer.expires_at < current_time_ms
          entity_manager.add_component component: timer.event.new, id: ent_id if timer.event
          if timer.repeat
            timer.expires_at = current_time_ms + timer.total
          else
            entity_manager.remove_component(klass: timer.class, id: ent_id)  
          end
        end
      else
        timer.expires_at = current_time_ms + timer.total
      end

    end
  end
end

class InputMappingSystem
  def update(entity_manager, dt, input)
    $window.close if input.down?(Gosu::KbEscape) || input.down?(Gosu::GpButton8)
    # entity_manager.each_entity KeyboardControl, Controls do |rec|
    #   keys, control = rec.components
    #   ent_id = rec.id
    #   control.move_left = input.down?(keys.move_left)
    #   control.move_right = input.down?(keys.move_right)
    #   control.move_up = input.down?(keys.move_up)
    #   control.move_down = input.down?(keys.move_down)
    # end
  end
end

class SoundSystem
  def update(entity_manager, dt, input)
    entity_manager.each_entity SoundEffectEvent do |rec|
      ent_id = rec.id
      effect = rec.get(SoundEffectEvent)
      entity_manager.remove_component klass: effect.class, id: ent_id
      Gosu::Sample.new(effect.sound_to_play).play
    end
  end
end

class BackgroundSystem
  def update(entity_manager, dt, input)
    map = entity_manager.find(Level).first.get(Level).map

    blobs = entity_manager.find(BackgroundBlob)
    (8 - blobs.size).times do 
      c = map.average_color
      x = [0 + rand(400), 1024 - rand(400)].sample
      y = [0 + rand(400), 1024 - rand(400)].sample
      color = Gosu::Color.rgba(c.red+rand(10)-5,c.green+rand(10)-5,c.blue+rand(10)-5,rand(10..70))
      entity_manager.add_entity Position.new(x,y,0),
        Boxed.new(rand(100..300),rand(100..300)), JoyColor.new(color),
        Velocity.new(rand(10)-5,rand(10)-5), BackgroundBlob.new
    end

    entity_manager.each_entity(Velocity, BackgroundBlob, Position, JoyColor) do |rec|
      ent_id = rec.id
      vel, blob, pos, color = rec.components

      scalar = dt/100.0
      pos.x += vel.x * scalar
      pos.y += vel.y * scalar

      if pos.x < -500 || pos.x > 1524 || pos.y > 1524 || pos.y < -500
        entity_manager.remove_entity ent_id 
      end
    end
  end
end

class RenderSystem

  def draw(target, entity_manager)
    # target.scale(0.5, 0.5) do
    monster_id = entity_manager.find(Monster)[0].id

    entity_manager.each_entity Position, JoyColor, Boxed do |rec|
      pos, color, boxed = rec.components
      ent_id = rec.id
      y_off = (boxed.squish_amount * boxed.squish_dir / 2.0)#.floor
      squish = (boxed.squish_amount / 2.0)#.floor
      half_squish = squish / 2.0

      c1 = c2 = c3 = c4 = color.color
      x1 = pos.x - boxed.width - half_squish
      y1 = pos.y - boxed.height + y_off + squish
      x2 = pos.x + boxed.width + half_squish
      y2 = y1
      x3 = x2
      y3 = pos.y + boxed.height + y_off - squish
      x4 = x1
      y4 = y3
      if monster_id == ent_id
        c = Gosu::Color::WHITE
        target.draw_quad(x1-1, y1-1, c, x2+1, y2-1, c, x3+1, y3+1, c, x4-1, y4+1, c, pos.z)
      end
      target.draw_quad(x1, y1, c1, x2, y2, c2, x3, y3, c3, x4, y4, c4, pos.z)
    end

    # EEWWW
    rec = entity_manager.find(Monster, Position, JoyColor, Debug).first
    if rec
      mon, pos, color, d = rec.components
      c = color.color
      x = 20
      y = 1024
      full_h = 60

      r = Gosu::Color::RED
      g = Gosu::Color::GREEN
      b = Gosu::Color::BLUE
      h = (c.red / 255.0 * full_h).round
      target.draw_quad(x, y, r, x, y-h, r, x+20, y-h, r, x+20, y, r, 3)

      h = (c.green / 255.0 * full_h).round
      target.draw_quad(x+20, y, g, x+20, y-h, g, x+40, y-h, g, x+40, y, g, 3)

      h = (c.blue / 255.0 * full_h).round
      target.draw_quad(x+40, y, b, x+40, y-h, b, x+60, y-h, b, x+60, y, b, 3)
    end

    # end

  end
end

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
def pretty_color(c)
  "[#{c.red},#{c.green},#{c.blue}]"
end

if $0 == __FILE__
  require 'gosu'
  puts pretty_color( ColorMix.mix(Gosu::Color::RED, Gosu::Color::YELLOW) )
  puts pretty_color( ColorMix.mix(Gosu::Color::BLUE, Gosu::Color::YELLOW) )
end

