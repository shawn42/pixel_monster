class TimerSystem
  def update(entity_store, delta, input, global_events)
    current_time_ms = input.total_time
    entity_store.each_entity Timer do |rec|
      timer = rec.get(Timer)
      ent_id = rec.id

      if timer.expires_at
        if timer.expires_at < current_time_ms
          if timer.event
            event_comp = timer.event.is_a?(Class) ? timer.event.new : timer.event
            entity_store.add_component component: event_comp, id: ent_id
          end
          if timer.repeat
            timer.expires_at = current_time_ms + timer.total
          else
            entity_store.remove_component(klass: timer.class, id: ent_id)
          end
        end
      else
        timer.expires_at = current_time_ms + timer.total
      end

    end
  end
end
