class FadingSystem
  ALPHA_RANGE = 50...255
  FADE_SPEED = 0.0001

  def update(entity_store, dt, input, global_events)
    entity_store.each_entity(GhostTile, JoyColor) do |rec|
      _, color = rec.components
      old_c = color.color
      alpha_dt = [dt * FADE_SPEED * 255, 1].max
      alpha = old_c.alpha - alpha_dt.round
      alpha = ALPHA_RANGE.max - (ALPHA_RANGE.min-alpha) if alpha < ALPHA_RANGE.min
      c = Gosu::Color.rgba(old_c.red, old_c.green, old_c.blue, alpha)
      color.color = c
    end
  end
end
