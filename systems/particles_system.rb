class ParticlesSystem
  def update(entity_store, dt, input, global_events)
    entity_store.each_entity(Velocity, Particle, Position, JoyColor, EntityTarget) do |rec|
      ent_id = rec.id
      vel, particle, pos, color, ent_target = rec.components

      scalar = dt/100.0
      pos.x += vel.x * scalar
      pos.y += vel.y * scalar

      target = entity_store.find_by_id(ent_target.id, Position)
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
        entity_store.remove_entity id: ent_id
      end
    end

  end
end