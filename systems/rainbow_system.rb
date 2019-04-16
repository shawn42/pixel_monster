class RainbowSystem
  def update(entity_store, dt, input, global_events)

    entity_store.each_entity(ChangeColorEvent, Rainbow, JoyColor) do |rec|
      rainbow_id = rec.id
      evt, rainbow, color = rec.components

      rainbow.color_index = (rainbow.color_index + 1) % rainbow.colors.size
      color.color = rainbow.colors[rainbow.color_index]
      entity_store.remove_component klass: ChangeColorEvent, id: rainbow_id
    end
  end
end
