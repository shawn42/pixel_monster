class SoundSystem
  def update(entity_store, dt, input, global_events)
    entity_store.each_entity SoundEffectEvent do |rec|
      ent_id = rec.id
      effect = rec.get(SoundEffectEvent)
      entity_store.remove_component klass: effect.class, id: ent_id
      Gosu::Sample.new(effect.sound_to_play).play
    end
  end
end
