class MonsterSystem
  JUMP_FORGIVENESS = 100 #ms
  RUN_FORGIVENESS = 20 #ms
  SQUISH_MAX = 8 #px
  SQUISH_DURATION = 150 #ms
  PEAK_DURATION = SQUISH_DURATION / 4.0 #ms
  JUMP_HEIGHT = 15
  SUPER_JUMP_HEIGHT = 25
  GRAVITY_PER_TICK = 0.75

  MAX_VEL = 15
  MIN_DIST = 80
  MIN_DIST_SQUARED = MIN_DIST * MIN_DIST
  JUMPS = ['sounds/jump1.wav','sounds/jump2.wav']
  COLLECT = 'sounds/collect.wav'
  WIN_SOUND = 'sounds/exit.wav'
  WRONG_COLOR = 'sounds/wrong_color.wav'
  DEATH_SOUND = 'sounds/death.wav'

  def update(entity_store, dt, input, global_events)
    level = entity_store.find(Level).first.get(Level)
    map = level.map

    if entity_store.find(DyingEvent).first
      level.failed!
    end

    monster_rec = entity_store.find(Monster, PlatformPosition, Position, JoyColor, Boxed, Velocity).first
    return if monster_rec.nil?
    ent_id = monster_rec.id
    monster, monster_platform, monster_pos, monster_color, boxed, vel = monster_rec.components

    if input.pressed?(Gosu::KbTab) || input.pressed?(Gosu::GpButton5)
      level.skip!
    end

    if input.down?(Gosu::KbR) || input.pressed?(Gosu::GpButton4) 
      death_at(entity_store, monster_pos.x, monster_pos.y, monster_color.color)
    end

    # TODO adjust this based on map size.. LUL
    if monster_pos.y > 1100
      death_at(entity_store, monster_pos.x, monster_pos.y-100, monster_color.color)
    end

    has_exit_color = has_exit_color?(map, monster_color.color)
    exit_recs = entity_store.find(Exit, Position, JoyColor, Boxed)
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
        entity_store.add_entity SoundEffectEvent.new(WIN_SOUND)
        timed = entity_store.find(Timed, LevelTimer).first.get(Timed)
        level.complete!(ms_to_complete: timed.accumulated_time_in_ms)
      else
        # entity_store.add_entity SoundEffectEvent.new(WRONG_COLOR)
      end
    end

    ground_below = on_ground?(map, monster_pos, boxed)

    moving_tiles = entity_store.find(MovableTile, Position, Boxed)
    moving_tile_below = on_moving_tile?(map, monster_pos, boxed, moving_tiles)

    on_moving_tile = moving_tile_below
    tile_below = on_ground = moving_tile_below || ground_below
    # puts "tile below: #{tile_below}"
    # puts "ON MOVING TILE" if on_moving_tile

    if on_ground
      monster_platform.last_grounded_at = input.total_time
      moving_boosters = entity_store.find(MovableTile, Position, Boxed, Bouncy)
      should_boost = should_boost?(map, monster_pos, boxed, moving_boosters)
      monster_platform.last_tile_bouncy = should_boost
    end

    old_y_vel = vel.y
    old_x_vel = vel.x

    vel.y = 0 if on_ground && !on_moving_tile

    if tile_below && on_moving_tile
      # TODO unify the idea of friction across on ground and moving tiles?
      dx = (tile_below.vel.x-vel.x)
      lock_on_cutoff = 0.01
      ms_to_come_to_vel = 150.0
      if dx.abs > lock_on_cutoff
        x_scale = (dt/ms_to_come_to_vel)
        x_scale = 1 if x_scale > 1
        vel.x += dx * x_scale
      else
        vel.x = tile_below.vel.x
      end
      vel.y = tile_below.vel.y
    end

    lateral_speed = dt/17.0
    lateral_speed /= 0.5 unless on_ground && !on_moving_tile
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
      entity_store.add_entity SoundEffectEvent.new(JUMPS.sample)
    elsif (input.released?(Gosu::KbUp) || input.released?(Gosu::GpButton1))
      if (monster_platform.last_jump == SUPER_JUMP_HEIGHT)
        vel.y = -monster_platform.last_jump * 0.6 if vel.y < -monster_platform.last_jump * 0.6
      else
        vel.y = -monster_platform.last_jump * 0.5 if vel.y < -monster_platform.last_jump * 0.5
      end
    elsif input.total_time - monster_platform.last_grounded_at > RUN_FORGIVENESS
      vel.y += GRAVITY_PER_TICK
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
    x_hit = false
    vel.x.round.abs.times do
      right_edge = level.width * Prefab::TILE_WIDTH - (Prefab::TILE_WIDTH/2)
      new_x = (monster_pos.x + x_step) % right_edge
      if map.blocked?(new_x-w, monster_pos.y-h) ||
        map.blocked?(new_x+w, monster_pos.y-h) ||
        map.blocked?(new_x-w, monster_pos.y+h) ||
        map.blocked?(new_x+w, monster_pos.y+h) ||
        in_moving_tile?(moving_tiles, new_x, monster_pos.y, w, h)
        vel.x = 0
        x_hit = true
        break
      else
        monster_pos.x = new_x
      end
    end

    y_hit = false
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
        y_hit = true
        break
      else
        monster_pos.y = new_y
      end
    end

    # DeathSystem
    entity_store.each_entity(Death, Position, Boxed) do |rec|
      _death, pos, death_box = rec.components

      if boxes_touch?(pos, death_box, monster_pos, boxed, 2)
        death_at(entity_store, monster_pos.x, monster_pos.y, monster_color.color)
      end
    end

    unless on_moving_tile
      if on_ground
        vel.x *= 0.9
      elsif
        vel.x *= 0.7
      end
    end

    if jumping
      boxed.squished_y_at = input.total_time
      boxed.squish_height = ((-36/MAX_VEL.to_f)*SQUISH_MAX)#.floor
      boxed.squish_y_dir = old_y_vel > 0 ? 1 : -1
    end

    if (y_hit && old_y_vel.abs > 0)
      entity_store.add_entity SoundEffectEvent.new(COLLECT) # TODO new sound for hitting?
      boxed.squished_y_at = input.total_time
      boxed.squish_height = (([old_y_vel.abs,6].max/MAX_VEL.to_f)*SQUISH_MAX)#.floor
      boxed.squish_y_dir = old_y_vel > 0 ? 1 : -1
    end

    if (x_hit && old_x_vel.abs > 0)
      # entity_store.add_entity SoundEffectEvent.new(COLLECT) # TODO new sound for hitting?
      boxed.squished_x_at = input.total_time
      boxed.squish_width = (([old_x_vel.abs,6].max/MAX_VEL.to_f)*SQUISH_MAX)#.floor
      boxed.squish_x_dir = old_x_vel > 0 ? 1 : -1
    end

    if boxed.squished_y_at
      squish_dt = input.total_time - boxed.squished_y_at
      if squish_dt < SQUISH_DURATION
        if squish_dt < PEAK_DURATION
          boxed.squish_y_amount = (boxed.squish_height * (squish_dt/PEAK_DURATION))#.floor
        else
          boxed.squish_y_amount = (boxed.squish_height * (1.0-(squish_dt-PEAK_DURATION)/(SQUISH_DURATION - PEAK_DURATION)))#.floor
        end
      else
        boxed.squished_y_at = nil
        boxed.squish_y_amount = 0
        boxed.squish_y_amount = 0
        boxed.squish_y_dir = 0
      end
    end

    if boxed.squished_x_at
      squish_dt = input.total_time - boxed.squished_x_at
      if squish_dt < SQUISH_DURATION
        if squish_dt < PEAK_DURATION
          boxed.squish_x_amount = (boxed.squish_width * (squish_dt/PEAK_DURATION))#.floor
        else
          boxed.squish_x_amount = (boxed.squish_width * (1.0-(squish_dt-PEAK_DURATION)/(SQUISH_DURATION - PEAK_DURATION)))#.floor
        end
      else
        boxed.squished_x_at = nil
        boxed.squish_x_amount = 0
        boxed.squish_x_amount = 0
        boxed.squish_x_dir = 0
      end
    end

    # ColorStuffSystem
    entity_store.each_entity(ColorSource, Position, JoyColor, Boxed, MovableTile) do |rec|
      src_id = rec.id
      src, pos, source_color, box, movable = rec.components
      sc = source_color.color

      x_off = pos.x - monster_pos.x
      y_off = pos.y - monster_pos.y
      dist = x_off*x_off+y_off*y_off

      if dist < MIN_DIST_SQUARED && boxes_touch?(pos, box, monster_pos, boxed, 3)
        blended_color = blend_colors(base: monster_color.color, absorbed: sc, weight: 0.15)
        monster_color.color = blended_color

        entity_store.remove_entity id: src_id

        entity_store.add_entity pos, EmitParticlesEvent.new(color: sc, target: monster_rec.id)
        entity_store.add_entity SoundEffectEvent.new(COLLECT)
        # TODO this is only a box to draw.. need to replace with movabletile?
        eid = Prefab.tile(entity_store: entity_store, x: pos.x, y: pos.y, color: Gosu::Color::GRAY)
        entity_store.add_component(id: eid, component: movable )
      end
    end

    # TODO: create a system that tracks all tiles that are 
    #       touching the monster to reuse these distance calcs
    entity_store.each_entity(ColorSource, Position, JoyColor, Boxed, GhostTile) do |rec|
      src_id = rec.id
      src, pos, source_color, box, border, movable = rec.components
      sc = source_color.color

      x_off = pos.x - monster_pos.x
      y_off = pos.y - monster_pos.y
      dist = x_off*x_off+y_off*y_off

      if dist < MIN_DIST_SQUARED && boxes_touch?(pos, box, monster_pos, boxed, 3)
        weight = sc.alpha / 255.0 * 0.15
        blended_color = blend_colors(base: monster_color.color, absorbed: sc, weight: weight)
        monster_color.color = blended_color

        entity_store.remove_entity id: src_id

        entity_store.add_entity pos, EmitParticlesEvent.new(color: sc, target: monster_rec.id)
        entity_store.add_entity SoundEffectEvent.new(COLLECT)
      end
    end 

    entity_store.each_entity(ColorSource, Position, JoyColor, Boxed) do |rec|
      src_id = rec.id
      src, pos, source_color, box = rec.components
      sc = source_color.color

      x_off = pos.x - monster_pos.x
      y_off = pos.y - monster_pos.y
      dist = x_off*x_off+y_off*y_off

      if dist < MIN_DIST_SQUARED && boxes_touch?(pos, box, monster_pos, boxed, 3)
        blended_color = blend_colors(base: monster_color.color, absorbed: sc, weight: 0.15)
        monster_color.color = blended_color

        entity_store.remove_entity id: src_id

        entity_store.add_entity pos, EmitParticlesEvent.new(color: sc, target: monster_rec.id)
        entity_store.add_entity SoundEffectEvent.new(COLLECT)
        Prefab.tile(entity_store: entity_store, x: pos.x, y: pos.y, color: Gosu::Color::GRAY)
      end
    end

    entity_store.each_entity(SuperColorSource, Position, JoyColor, Boxed, Border, MovableTile) do |rec|
      src_id = rec.id
      src, pos, source_color, box, border, movable = rec.components
      sc = source_color.color

      x_off = pos.x - monster_pos.x
      y_off = pos.y - monster_pos.y
      dist = x_off*x_off+y_off*y_off

      if dist < MIN_DIST_SQUARED && boxes_touch?(pos, box, monster_pos, boxed, 3)
        monster_color.color = sc

        entity_store.remove_entity id: src_id

        entity_store.add_entity pos, EmitParticlesEvent.new(color: sc, target: monster_rec.id)
        entity_store.add_entity SoundEffectEvent.new(COLLECT)
        # TODO this is only a box to draw.. need to replace with movabletile?
        eid = Prefab.tile(entity_store: entity_store, x: pos.x, y: pos.y, color: Gosu::Color::GRAY)
        entity_store.add_component( id:eid, component: movable )
      else
        # TODO make this more of a pulse effect
        change = (-2..3).to_a.sample
        border.width = clamp(border.width + change, 14..18)
        border.height = clamp(border.height + change, 14..18)
      end
    end 
 
    entity_store.each_entity(SuperColorSource, Position, JoyColor, Boxed, Border) do |rec|
      src_id = rec.id
      src, pos, source_color, box, border = rec.components
      sc = source_color.color

      x_off = pos.x - monster_pos.x
      y_off = pos.y - monster_pos.y
      dist = x_off*x_off+y_off*y_off

      if dist < MIN_DIST_SQUARED && boxes_touch?(pos, box, monster_pos, boxed, 3)
        monster_color.color = sc

        entity_store.remove_entity id: src_id

        entity_store.add_entity pos, EmitParticlesEvent.new(color: sc, target: monster_rec.id)
        entity_store.add_entity SoundEffectEvent.new(COLLECT)
        Prefab.tile(entity_store: entity_store, x: pos.x, y: pos.y, color: Gosu::Color::GRAY)
      else
        # TODO make this more of a pulse effect
        change = (-2..2).to_a.sample
        border.width = clamp(border.width + change, 14..18)
        border.height = clamp(border.height + change, 14..18)
      end
    end

    # BouncySystem
    entity_store.each_entity(Position, Boxed, Bouncy) do |rec|
      bouncy_id = rec.id
      pos, bouncy_box, bouncy = rec.components

      if (rand(10) < 2)
        entity_store.add_entity pos, EmitParticlesEvent.new(color: Gosu::Color::WHITE, intensity: 15)
      end
    end


    # BlackHoleSystem
    entity_store.each_entity(BlackHole, Position, JoyColor, ColorSink, Boxed) do |rec|
      black_hole_id = rec.id
      black_hole, pos, black_hole_color, subtract_color, box = rec.components

      if boxes_touch?(pos, box, monster_pos, boxed)
        if would_subtract?(base: monster_color.color, subtracted: subtract_color.color)
          entity_store.add_entity monster_pos, EmitParticlesEvent.new(color: subtract_color.color, target: black_hole_id, intensity: 100)
          monster_color.color = subtract_colors(base: monster_color.color, subtracted: subtract_color.color)
          entity_store.add_entity SoundEffectEvent.new(COLLECT)
        end
      end
      # entity_store.add_entity pos.nearby(32,32), EmitParticlesEvent.new(color:Prefab::COLORS.sample , target: black_hole_id, intensity: 1)
      if rand(3) == 0
        entity_store.add_entity pos.nearby(32,32), EmitParticlesEvent.new(color:subtract_color.color, target: black_hole_id, intensity: 1)
      end
    end

    # MovableTilesSystem
    moving_tiles.each do |rec|
      moveable_tile, tile_pos, tile_box = rec.components

      next if moveable_tile.path.nil?
      path_target_range = 1
      target = tile_to_world_coords(map, moveable_tile.path.current)
      dist = (tile_pos.to_vec - target).magnitude
      close_enough_to_target = dist < path_target_range

      if close_enough_to_target
        moveable_tile.path.next!
        target = tile_to_world_coords(map, moveable_tile.path.current)
      end

      # move toward target
      tx = target.x-tile_pos.x
      ty = target.y-tile_pos.y

      moveable_tile.dir_vec = vec(tx,ty).unit

      thrust = 1
      vel_x = dist > 0 ? (tx/dist)*thrust : 0
      vel_y = dist > 0 ? (ty/dist)*thrust : 0

      moveable_tile.vel.x = vel_x
      moveable_tile.vel.y = vel_y

      x_step = vel_x < 0 ? -1 : 1
      w = boxed.width
      h = boxed.height
      vel_x.abs.round.times do
        if boxes_touch?(monster_pos, boxed, vec(tile_pos.x+x_step, tile_pos.y), tile_box, 0)
          monster_pos.x += x_step
          if in_moving_tile?(moving_tiles, monster_pos.x + x_step, monster_pos.y, w, h) ||
            map.blocked?(monster_pos.x-w, monster_pos.y-h) ||
            map.blocked?(monster_pos.x+w, monster_pos.y-h) ||
            map.blocked?(monster_pos.x-w, monster_pos.y+h) ||
            map.blocked?(monster_pos.x+w, monster_pos.y+h)
            death_at(entity_store, monster_pos.x, monster_pos.y, monster_color.color)
          end
        end
        tile_pos.x += x_step
      end

      y_step = vel_y < 0 ? -1 : 1
      vel_y.abs.round.times do
        if boxes_touch?(monster_pos, boxed, vec(tile_pos.x, tile_pos.y+y_step), tile_box, 0)
          monster_pos.y += y_step

          if in_moving_tile?(moving_tiles, monster_pos.x, monster_pos.y+y_step, w, h) ||
            map.blocked?(monster_pos.x-w, monster_pos.y-h) ||
            map.blocked?(monster_pos.x+w, monster_pos.y-h) ||
            map.blocked?(monster_pos.x-w, monster_pos.y+h) ||
            map.blocked?(monster_pos.x+w, monster_pos.y+h)
            death_at(entity_store, monster_pos.x, monster_pos.y, monster_color.color)
          end

        end
        tile_pos.y += y_step
      end

    end
  end

  private

  def death_at(entity_store, x, y, color)
    monster_rec = entity_store.find(Monster, PlatformPosition, Position, JoyColor, Boxed, Velocity).first
    return if monster_rec.nil? # already dead this frame
    entity_store.remove_entity id: monster_rec.id
    # entity_store.remove_component(klass: Monster, id: monster_rec.id)

    entity_store.add_entity SoundEffectEvent.new(DEATH_SOUND)
    entity_store.add_entity Timer.new(:dying, 600, false, DyingEvent)
    
    entity_store.add_entity Position.new(x,y), EmitParticlesEvent.new(color: color, target: nil, intensity: 40, speed:(-7..7).to_a, size: (2..6).to_a)
  end

  def clamp(val, range)
    if range.cover? val
      val
    else
      if val < range.begin
        range.begin 
      else
        range.end 
      end
    end
  end


  def in_moving_tile?(moveable_tiles, x, y, w, h)
    moveable_tiles.any? do |rec|
      tile, tile_pos, tile_box = rec.components
      point_in_box?(x-w,y-h, tile_pos.x,tile_pos.y,tile_box.width,tile_box.height) ||
        point_in_box?(x+w,y-h, tile_pos.x,tile_pos.y,tile_box.width,tile_box.height) ||
        point_in_box?(x-w,y+h, tile_pos.x,tile_pos.y,tile_box.width,tile_box.height) ||
        point_in_box?(x+w,y+h, tile_pos.x,tile_pos.y,tile_box.width,tile_box.height)
    end
  end

  # box.w = half width
  # x,y are center
  def boxes_touch?(a_pos, a_box, b_pos, b_box, buffer=1)
    diff = b_pos.to_vec - a_pos.to_vec
    diff.x.abs <= (a_box.w + b_box.w + buffer) &&
      diff.y.abs <= (a_box.h + b_box.h + buffer)
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

    map.in_exit?(x-w, y+h) || map.in_exit?(x+w, y+h)
  end

  def on_moving_tile?(map, pos, box, moving_tiles)
    x = pos.x
    y = pos.y
    w = box.width
    h = box.height
    py = y+h+1 # one pixel above, actually
    moving_tiles.each do |rec|
      tile, tile_pos, tile_box = rec.components
      return tile if 
        # on it
        point_in_box?(x-w,py, tile_pos.x,tile_pos.y,tile_box.width,tile_box.height) ||
        point_in_box?(x+w,py, tile_pos.x,tile_pos.y,tile_box.width,tile_box.height)
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

  def tile_to_world_coords(map, v)
    map.map_to_world(v.x, v.y)
  end

end