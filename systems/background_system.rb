class BackgroundSystem
  def update(entity_store, dt, input, global_events)
    map = entity_store.find(Level).first.get(Level).map

    blobs = entity_store.find(BackgroundBlob)
    (8 - blobs.size).times do
      c = map.average_color
      x = [0 + rand(400), 1024 - rand(400)].sample
      y = [0 + rand(400), 1024 - rand(400)].sample
      color = Gosu::Color.rgba(c.red+rand(10)-5,c.green+rand(10)-5,c.blue+rand(10)-5,rand(10..70))
      entity_store.add_entity Position.new(x,y,0),
        Boxed.new(rand(100..300),rand(100..300)), JoyColor.new(color),
        Velocity.new(x: rand(10)-5, y: rand(10)-5), BackgroundBlob.new
    end

    entity_store.each_entity(Velocity, BackgroundBlob, Position, JoyColor) do |rec|
      ent_id = rec.id
      vel, blob, pos, color = rec.components

      scalar = dt/100.0
      pos.x += vel.x * scalar
      pos.y += vel.y * scalar

      if pos.x < -500 || pos.x > 1524 || pos.y > 1524 || pos.y < -500
        entity_store.remove_entity id: ent_id
      end
    end
  end
end
