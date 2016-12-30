class World
  def initialize(systems)
    @systems = systems
  end

  def update(entity_manager, delta, input_snapshot)
    global_events = []
    @systems.map do |sys|
      sys.update entity_manager, delta, input_snapshot, global_events
    end

    {entity_manager: entity_manager,
     global_events: global_events,
    }
  end

end
