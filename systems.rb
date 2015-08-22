# terrible vector class  =P
class Array
  def x; at(0) end
  def y; at(1) end
  def x=(x); self[0] = x end
  def y=(y); self[1] = y end
end

module Enumerable
  def sum
    size > 0 ? inject(0, &:+) : 0
  end
end

class ParticlesEmitterSystem
  def update(entity_manager, dt, input)
    entity_manager.each_entity(EmitParticlesEvent, Position) do |rec|
      ent_id = rec.id
      evt, pos = rec.components

      speed = (-10..10).to_a
      20.times do
        entity_manager.add_entity pos.dup, Particle.new, 
          JoyColor.new(evt.color), 
          Velocity.new(speed.sample, speed.sample), Boxed.new(rand(3),rand(3))
      end

      entity_manager.remove_component klass: EmitParticlesEvent, id: ent_id
    end
  end
end

class MonsterSystem
  MAX_VEL = 15
  MIN_DIST = 40
  MIN_DIST_SQUARED = MIN_DIST * MIN_DIST

  def initialize(level)
    @map = level.map
  end

  def update(entity_manager, dt, input)
    monster_rec = entity_manager.find(Monster, Position, JoyColor, Boxed, Velocity).first
    ent_id = monster_rec.id
    monster, monster_pos, monster_color, boxed, vel = monster_rec.components
    mc = monster_color.color

    speed = 70*dt/1000.0

    on_ground = on_ground?(monster_pos, boxed)
    vel.y = 0 if on_ground
    lateral_speed = 2
    lateral_speed /= 0.5 unless on_ground

    if input.down? Gosu::KbLeft
      vel.x -= lateral_speed
    elsif input.down? Gosu::KbRight
      vel.x += lateral_speed
    end

    if input.down?(Gosu::KbUp) && on_ground
      vel.y -= 30
    else
      # TODO gravity, break out sep velocity
      vel.y += 0.75
    end

    if vel.x > MAX_VEL
      vel.x = MAX_VEL 
    elsif vel.x < -MAX_VEL
      vel.x = -MAX_VEL
    end
    if vel.y > MAX_VEL
      vel.y = MAX_VEL 
    elsif vel.y < -MAX_VEL
      vel.y = -MAX_VEL
    end

    # TODO use BB
    x_step = vel.x < 0 ? -1 : 1
    w = boxed.width
    h = boxed.height
    vel.x.round.abs.times do
      new_x = monster_pos.x + x_step
      if @map.blocked?(new_x-w, monster_pos.y-h) ||
        @map.blocked?(new_x+w, monster_pos.y-h) ||
        @map.blocked?(new_x-w, monster_pos.y+h) ||
        @map.blocked?(new_x+w, monster_pos.y+h)
        break
      else
        monster_pos.x = new_x
      end
    end

    y_step = vel.y < 0 ? -1 : 1
    vel.y.round.abs.times do
      new_y = monster_pos.y + y_step
      if @map.blocked?(monster_pos.x-w, new_y-h) ||
        @map.blocked?(monster_pos.x+w, new_y-h) ||
        @map.blocked?(monster_pos.x-w, new_y+h) ||
        @map.blocked?(monster_pos.x+w, new_y+h)
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


    # ColorStuffSystem
    entity_manager.each_entity(ColorSource, Position, JoyColor) do |rec|
      src_id = rec.id
      src, pos, source_color = rec.components
      sc = source_color.color

      x_off = pos.x - monster_pos.x
      y_off = pos.y - monster_pos.y
      dist = x_off*x_off+y_off*y_off

      if dist < MIN_DIST_SQUARED
        blended_color = blend_colors(base: mc, absorbed: sc, weight: 0.1)
        monster_color.color = blended_color
        
        entity_manager.remove_entity src_id
        entity_manager.add_entity pos, EmitParticlesEvent.new(color: sc)
      end
    end
  end

  def on_ground?(pos, box)
    x = pos.x
    y = pos.y
    w = box.width
    h = box.height

    @map.blocked?(pos.x-w, pos.y+h+1) || @map.blocked?(pos.x+w, pos.y+h+1)
  end

  def blend_colors(base: , absorbed: , weight:)
    red = base.red + (absorbed.red - base.red)*weight
    green = base.green + (absorbed.green - base.green)*weight
    blue = base.blue + (absorbed.blue - base.blue)*weight

    Gosu::Color.rgba(red, green, blue, base.alpha)
  end
end
class ParticlesSystem
  def update(entity_manager, dt, input)
    entity_manager.each_entity(Velocity, Particle, Position, JoyColor) do |rec|
      ent_id = rec.id
      vel, particle, pos, color = rec.components

      scalar = dt/100.0
      pos.x += vel.x * scalar
      pos.y += vel.y * scalar

      c = color.color
      color.color = Gosu::Color.rgba(c.red,c.green,c.blue,c.alpha-10*scalar)
      entity_manager.remove_entity ent_id if color.color.alpha <= 0
    end
  end
end

class TimerSystem
  def update(entity_manager, current_time_ms, input)
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
    exit if input.down?(Gosu::KbEscape)
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

class ClickSystem
  def initialize
    @up = true
  end
  # TODO this should be handled at the "input" layer

  def update(entity_manager, dt, input)
    mouse_x = input.mouse_pos[:x]
    mouse_y = input.mouse_pos[:y]
    mouse_down = input.down?(Gosu::MsLeft)
    if @up && mouse_down
      @up = false
      entity_manager.each_entity Clickable, Boxed, Position do |rec|
        clickable, boxed, pos = rec.components
        ent_id = rec.id
        if (mouse_x - pos.x).abs < boxed.width and (mouse_y - pos.y).abs < boxed.height
          entity_manager.add_component component: ClickedEvent.new(x: mouse_x, y: mouse_y), id: ent_id
        end
      end
    end
    @up = true if !mouse_down
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

class RenderSystem

  def draw(target, entity_manager)
    entity_manager.each_entity Position, JoyColor, Boxed do |rec|
      pos, color, boxed = rec.components
      ent_id = rec.id
      c1 = c2 = c3 = c4 = color.color
      x1 = pos.x - boxed.width
      y1 = pos.y - boxed.height
      x2 = pos.x + boxed.width
      y2 = y1
      x3 = x2
      y3 = pos.y + boxed.height
      x4 = x1
      y4 = y3
      target.draw_quad(x1, y1, c1, x2, y2, c2, x3, y3, c3, x4, y4, c4, 2)
    end

    # entity_manager.each_entity Position, JoyImage do |rec|
    #   pos, image = rec.components
    #   ent_id = rec.id
    #   z = 1
    #   image.image.draw_rot pos.x, pos.y, z, 0
    # end

    # entity_manager.each_entity Position, Score, JoyColor do |rec|
    #   pos, s, c = rec.components
    #   ent_id = rec.id
    #   @font ||= Gosu::Font.new target, '', 32
    #   z = 99
    #   @font.draw s.points, pos.x, pos.y, z, 1, 1, c.color
    # end
  end
end

