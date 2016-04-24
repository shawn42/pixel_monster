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
          Velocity.new(x: SPEED.sample, y: SPEED.sample), Boxed.new(rand(3),rand(3)), EntityTarget.new(evt.target)
      end

      # entity_manager.remove_component klass: EmitParticlesEvent, id: ent_id
      entity_manager.remove_entity ent_id
    end
  end
end

class MonsterSystem
  JUMP_FORGIVENESS = 100 #ms
  RUN_FORGIVENESS = 20 #ms
  SQUISH_MAX = 8 #px
  SQUISH_DURATION = 150 #ms
  PEAK_DURATION = SQUISH_DURATION / 4.0 #ms
  JUMP_HEIGHT = 15
  SUPER_JUMP_HEIGHT = 25

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

    if input.pressed?(Gosu::KbTab) || input.pressed?(Gosu::GpButton5)
      level.complete!
    end

    if input.down?(Gosu::KbR) || input.pressed?(Gosu::GpButton4) || monster_pos.y > 1100
      level.failed!
    end

    has_exit_color = has_exit_color?(map, monster_color.color)
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

    ground_below = on_ground?(map, monster_pos, boxed)

    moving_tiles = entity_manager.find(MovableTile, Position, Boxed)

    moving_tile_below = on_moving_tile?(map, monster_pos, boxed, moving_tiles)
    # puts "moving tile below: #{moving_tile_below}"
    on_moving_tile = moving_tile_below

    tile_below = on_ground = ground_below || moving_tile_below
    # puts "tile below: #{tile_below}"

    if on_ground
      monster_platform.last_grounded_at = input.total_time
      moving_boosters = entity_manager.find(MovableTile, Position, Boxed, Bouncy)
      should_boost = should_boost?(map, monster_pos, boxed, moving_boosters)
      monster_platform.last_tile_bouncy = should_boost
    end

    old_y_vel = vel.y

    vel.y = 0 if on_ground && !on_moving_tile
    lateral_speed = dt/17.0
    lateral_speed /= 0.5 unless on_ground && !on_moving_tile

    if tile_below && on_moving_tile
      # TODO unify the idea of friction across on ground and moving tiles?
      dx = (tile_below.vel.x-vel.x)
      dy = (tile_below.vel.y-vel.y)
      lock_on_cutoff = 0.0001
      ms_to_come_to_vel = 150.0
      if dx.abs > lock_on_cutoff
        x_scale = (dt/ms_to_come_to_vel)
        x_scale = 1 if x_scale > 1
        vel.x += dx * x_scale
      else
        vel.x = tile_below.vel.x
      end
      if dy.abs > lock_on_cutoff
        y_scale = (dt/ms_to_come_to_vel)
        y_scale = 1 if y_scale > 1
        vel.y += dy * y_scale
      else
        vel.y = tile_below.vel.y
      end
    end

    if input.down?(Gosu::KbLeft) || input.down?(Gosu::GpLeft)
      vel.x -= lateral_speed
    elsif input.down?(Gosu::KbRight) || input.down?(Gosu::GpRight)
      vel.x += lateral_speed
    end

    can_jump = (input.total_time - monster_platform.last_grounded_at) < JUMP_FORGIVENESS
    jumping = false
    jump_strength = monster_platform.last_tile_bouncy ? SUPER_JUMP_HEIGHT : JUMP_HEIGHT
    if (input.pressed?(Gosu::KbUp) || input.pressed?(Gosu::GpButton1)) && can_jump
      monster_platform.last_jump = jump_strength
      jumping = true
      vel.y -= jump_strength
      monster_platform.last_grounded_at = -1
      monster_platform.last_tile_bouncy = false
      entity_manager.add_entity SoundEffectEvent.new(JUMPS.sample)
    elsif (input.released?(Gosu::KbUp) || input.released?(Gosu::GpButton1))
      if (monster_platform.last_jump == SUPER_JUMP_HEIGHT)
        vel.y = -monster_platform.last_jump * 0.6 if vel.y < -monster_platform.last_jump * 0.6
      else
        vel.y = -monster_platform.last_jump * 0.5 if vel.y < -monster_platform.last_jump * 0.5
      end
    elsif input.total_time - monster_platform.last_grounded_at > RUN_FORGIVENESS
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
        map.blocked?(new_x+w, monster_pos.y+h) ||
        in_moving_tile?(moving_tiles, new_x, monster_pos.y, w, h)
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
        map.blocked?(monster_pos.x+w, new_y+h) ||
        in_moving_tile?(moving_tiles, monster_pos.x, new_y, w, h)
        vel.y = 0
        monster_platform.jump_time = 0
        y_hit = vel.y
        break
      else
        monster_pos.y = new_y
      end
    end

    if on_ground
      vel.x *= 0.9
    elsif
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

    entity_manager.each_entity(ColorSource, Position, JoyColor, Boxed) do |rec|
      src_id = rec.id
      src, pos, source_color, box = rec.components
      sc = source_color.color

      x_off = pos.x - monster_pos.x
      y_off = pos.y - monster_pos.y
      dist = x_off*x_off+y_off*y_off

      if dist < MIN_DIST_SQUARED && boxes_touch?(pos, box, monster_pos, boxed)
        blended_color = blend_colors(base: monster_color.color, absorbed: sc, weight: 0.15)
        monster_color.color = blended_color

        # TODO can I remove while iterating?!?!?
        dead_ents ||= []
        dead_ents << src_id
        # entity_manager.remove_entity src_id
        # TODO can I add while iterating safely?
        entity_manager.add_entity pos, EmitParticlesEvent.new(color: sc, target: monster_rec.id)
        entity_manager.add_entity SoundEffectEvent.new(COLLECT)
      end
    end

    # BouncySystem
    entity_manager.each_entity(Position, Boxed, Bouncy) do |rec|
      bouncy_id = rec.id
      pos, bouncy_box, bouncy = rec.components

      if (rand(10) < 2)
        entity_manager.add_entity pos, EmitParticlesEvent.new(color: Gosu::Color::WHITE, intensity: 15)
      end
    end


    # BlackHoleSystem
    entity_manager.each_entity(BlackHole, Position, JoyColor, ColorSink, Boxed) do |rec|
      black_hole_id = rec.id
      black_hole, pos, black_hole_color, subtract_color, box = rec.components

      if boxes_touch?(pos, box, monster_pos, boxed)
        if would_subtract?(base: monster_color.color, subtracted: subtract_color.color)
          entity_manager.add_entity monster_pos, EmitParticlesEvent.new(color: subtract_color.color, target: black_hole_id, intensity: 100)
          monster_color.color = subtract_colors(base: monster_color.color, subtracted: subtract_color.color)
          entity_manager.add_entity SoundEffectEvent.new(COLLECT)
        end
      end
      # entity_manager.add_entity pos.nearby(32,32), EmitParticlesEvent.new(color:Prefab::COLORS.sample , target: black_hole_id, intensity: 1)
      if rand(3) == 0
        entity_manager.add_entity pos.nearby(32,32), EmitParticlesEvent.new(color:subtract_color.color, target: black_hole_id, intensity: 1)
      end
    end

    # DeathSystem
    entity_manager.each_entity(Death, Position, Boxed) do |rec|
      death_id = rec.id
      death, pos, death_box = rec.components

      level.failed! if boxes_touch?(pos, death_box, monster_pos, boxed, 2)
    end

    # MovableTilesSystem
    moving_tiles.each do |rec|
      moveable_tile, tile_pos, tile_box = rec.components

      # TODO: implement 'tile_to_world_coords' and 'abs_dist' and 'path_target_range'
      target = tile_to_world_coords(moveable_tile.path.current)
      close_enough_to_target = abs_dist(moveable_tile.pos - target) < path_target_range
      if close_enough_to_target
        moveable_tile.path.next
        target = tile_to_world_coords(moveable_tile.path.current)
      end

      # move toward target
      tx = target.x-tile_pos.x
      ty = target.y-tile_pos.y

      moveable_tile.dir_vec = vec(tx,ty).unit
      dist = Math.sqrt(tx*tx+ty*ty)
      if (dist < 1)
        # XXX is this clause relevant given the updated logic above?
        # if tile_pos.x < 300
        #   moveable_tile.world_target = vec(tile_pos.x+512,tile_pos.y)
        # else
        #   moveable_tile.world_target = vec(tile_pos.x-128,tile_pos.y)
        # end
      else
        thrust = 1
        vel_x = (tx/dist)*thrust;
        vel_y = (ty/dist)*thrust;

        moveable_tile.vel.x = vel_x
        moveable_tile.vel.y = vel_y

        x_step = vel_x < 0 ? -1 : 1
        vel_x.abs.round.times do
          if boxes_touch?(monster_pos, boxed, vec(tile_pos.x+x_step, tile_pos.y), tile_box, 0)
            monster_pos.x += x_step
            # TODO kill player if they cannot move
          end
          tile_pos.x += x_step
        end

        y_step = vel_y < 0 ? -1 : 1
        vel_y.abs.round.times do
          if boxes_touch?(monster_pos, boxed, vec(tile_pos.x, tile_pos.y+y_step), tile_box, 0)
            monster_pos.y += y_step
            # TODO kill player if they cannot move
          end
          tile_pos.y += y_step
        end
      end

    end


    if dead_ents
      dead_ents.each do |dead_id|
        entity_manager.remove_entity dead_id
      end
    end
  end

  # XXX
  # NEIGHBOR_VECS = [
  #   Vec::UP,
  #   Vec::RIGHT,
  #   Vec::DOWN,
  #   Vec::LEFT,
  # ]
  # def choose_next_target!(moveable_tile)
  #   current_dir_vec = moveable_tile.dir_vec
  #   path = moveable_tile.path
  #   path_target = moveable_tile.path_target
  #
  #   cont_path_target = path_target + current_dir_vec
  #   if path.include?(cont_path_target)
  #     mov
  #     return cont_path_target
  #   else
  #     NEIGHBOR_VECS.each do |nvec|
  #       path_target = path_target + nvec
  #     end
  #   end
  # end

  def in_moving_tile?(moveable_tiles, x, y, w, h)
    moveable_tiles.any? do |rec|
      tile, tile_pos, tile_box = rec.components
      point_in_box?(x-w,y-h, tile_pos.x,tile_pos.y,tile_box.width,tile_box.height) ||
        point_in_box?(x+w,y-h, tile_pos.x,tile_pos.y,tile_box.width,tile_box.height) ||
        point_in_box?(x-w,y+h, tile_pos.x,tile_pos.y,tile_box.width,tile_box.height) ||
        point_in_box?(x+w,y+h, tile_pos.x,tile_pos.y,tile_box.width,tile_box.height)
    end
  end

  def boxes_touch?(a_pos, a_box, b_pos, b_box, fudge=10)
    ((a_pos.x - b_pos.x).abs * 2 <= (a_box.width*2 + b_box.width*2+fudge)) &&
           ((a_pos.y - b_pos.y).abs * 2 <= (a_box.height*2 + b_box.height*2+fudge))
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

  def on_moving_tile?(map, pos, box, moving_tiles)
    x = pos.x
    y = pos.y
    w = box.width
    h = box.height
    py = y+h+1
    moving_tiles.each do |rec|
      tile, tile_pos, tile_box = rec.components
      return tile if point_in_box?(pos.x-w,py, tile_pos.x,tile_pos.y,tile_box.width,tile_box.height) ||
        point_in_box?(pos.x+w,py, tile_pos.x,tile_pos.y,tile_box.width,tile_box.height)
    end
    nil
  end

  def point_in_box?(px,py, sx,sy,sw,sh)
    (sx-sw) <= px && px <= (sx+sw) && (sy-sh) <= py && py <= (sy+sh)
  end

  def on_ground?(map, pos, box)
    w = box.width
    h = box.height
    py = pos.y+h+1

    map.blocked?(pos.x-w, py) || map.blocked?(pos.x+w, py)
  end

  def should_boost?(map, pos, box, moving_boosters)
    x = pos.x
    y = pos.y
    w = box.width
    h = box.height
    left_tile = map.at(pos.x-w, pos.y+h+1)
    right_tile = map.at(pos.x+w, pos.y+h+1)
    (left_tile && left_tile.is_a?(BouncyTile)) || (right_tile && right_tile.is_a?(BouncyTile)) || moving_boost?(pos, box, moving_boosters)
  end

  def moving_boost?(pos, box, moving_tiles)
    w = box.width
    h = box.height
    py = pos.y+h+1
    moving_tiles.any? do |rec|
      tile, tile_pos, tile_box, bouncy = rec.components
      point_in_box?(pos.x-w,py, tile_pos.x,tile_pos.y,tile_box.width,tile_box.height) ||
        point_in_box?(pos.x+w,py, tile_pos.x,tile_pos.y,tile_box.width,tile_box.height)
    end
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
    @n ||= 0
    @n += 1
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

  # TODO implement me
  def tile_to_world_coords(v)
    return vec(0,0)
  end

  # TODO implement me
  def abs_dist(v1,v2)
    0
  end

  # TODO implement me
  def path_target_range
    32
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
      target_pos =
        if target
          target.get(Position)
        else
          Position.new(pos.x, pos.y-70)
        end

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

class PathingSystem
  def update(entity_manager, dt, input)
    # map = entity_manager.find(Level).first.get(Level).map

    entity_manager.each_entity(Velocity, Position, Pathable) do |rec|
      ent_id = rec.id
      vel, pos, pathable = rec.components

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
        Velocity.new(x: rand(10)-5, y: rand(10)-5), BackgroundBlob.new
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

    entity_manager.each_entity(Position, Boxed, Death) do |rec|
      death_id = rec.id
      pos, death_box, death = rec.components

      x = pos.x
      y = pos.y
      w = death_box.width
      h = death_box.height
      n = 50

      n.times do
        rx = rand(x-w-4..x+w)
        ry = rand(y-h-4..y+h)
        rw = rand(2..4)
        rh = rand(2..4)
        rc = Gosu::Color.rgba(rand(200),rand(200),rand(200),rand(200))
        z = 4

        target.draw_quad(rx, ry, rc, rx+rw, ry, rc, rx+rw, ry+rh, rc, rx, ry+rh, rc, z)
      end
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
