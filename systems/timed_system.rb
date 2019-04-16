class TimedSystem
  def update(entity_store, delta, input, global_events)
    entity_store.each_entity Timed do |rec|
      timed = rec.get(Timed)
      ent_id = rec.id
      timed.accumulated_time_in_ms += delta
    end
  end
end
