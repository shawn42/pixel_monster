class World
  def initialize(systems)
    @systems = systems
  end

  def update(entity_store, delta, input_snapshot)
    global_events = []
    @systems.map do |sys|
      sys.update entity_store, delta, input_snapshot, global_events
    end

    {entity_store: entity_store,
     global_events: global_events,
    }
  end

end
