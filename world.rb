class World
  attr_accessor :entity_manager
  def initialize(entity_manager, systems)
    @entity_manager = entity_manager
    @systems = systems
  end

  def reset!
    @entity_manager.clear!
  end

  def update(delta, input_snapshot)
    @systems.each do |sys|
      sys.update entity_manager, delta, input_snapshot
    end
  end

end
