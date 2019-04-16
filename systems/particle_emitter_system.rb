class ParticlesEmitterSystem
  SPEED = (-3..3).to_a
  POSITIONS = (-15..15).to_a
  SIZE = (1..3).to_a

  USE_HELPFUL_COLORS = true
  def update(entity_store, dt, input, global_events)
    entity_store.each_entity(EmitParticlesEvent, Position) do |rec|
      ent_id = rec.id
      evt, pos = rec.components

      if USE_HELPFUL_COLORS
        num_of_red_particles = (evt.color.red / 255.0 * evt.intensity).ceil
        num_of_green_particles = (evt.color.green / 255.0 * evt.intensity).ceil
        num_of_blue_particles = (evt.color.blue / 255.0 * evt.intensity).ceil
        create_colored_particle(entity_store, num_of_red_particles, Gosu::Color::RED, evt, pos)
        create_colored_particle(entity_store, num_of_green_particles, Gosu::Color::GREEN, evt, pos)
        create_colored_particle(entity_store, num_of_blue_particles, Gosu::Color::BLUE, evt, pos)
      else
        create_colored_particle(entity_store, evt.intensity, evt.color, evt, pos)
      end

      entity_store.remove_entity id: ent_id
    end
  end

  private

  def create_colored_particle(entity_store, intensity, color, evt, pos)
    intensity.times do
      speed = evt.speed || SPEED
      size = evt.size || SIZE
      new_ent = entity_store.add_entity Position.new(pos.x+POSITIONS.sample, pos.y+POSITIONS.sample, 3),
        Particle.new, JoyColor.new(color),
        Velocity.new(x: speed.sample, y: speed.sample), Boxed.new(size.sample,size.sample), EntityTarget.new(evt.target)
    end
  end


end
