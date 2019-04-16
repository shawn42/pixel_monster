class CameraSystem
  def update(entity_store, dt, input, global_events)
    camera = entity_store.find(Camera).first.components.first

    entity_store.each_entity(ZoomCameraOperation) do |rec|
      op = rec.components.first
      op.ttl -= dt
      if op.ttl <= 0
        op.ttl = 0
        entity_store.remove_entity id: rec.id
      end
      camera.scale = 1 + op.target_scale * (op.duration-op.ttl)/op.duration.to_f
      camera.target_x = op.target_x
      camera.target_y = op.target_y
    end

  end
end
