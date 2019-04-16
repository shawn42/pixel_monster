class TimedLevelSystem
  def update(entity_store, dt, input, global_events)
   timed, label, lt  = entity_store.find(Timed, Label, LevelTimer).first.components
   label.text = (timed.accumulated_time_in_ms/1000).round(1)
  end
end
