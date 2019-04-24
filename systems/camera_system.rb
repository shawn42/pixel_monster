class CameraSystem
  def update(entity_store, dt, input, global_events)
    # NOTE general scrolling is a bad idea
    # camera = entity_store.first(Camera, Position)
    # cam, pos = camera.components
    # target = entity_store.find_by_id(cam.target_id, Position) if cam.target_id
    # if target
    #   target_pos = target.get(Position)
    #   pos.x = target_pos.x
    #   pos.y = target_pos.y
    # end


    # entity_store.each_entity(ZoomCameraOperation) do |rec|
    #   op = rec.components.first
    #   op.ttl -= dt
    #   if op.ttl <= 0
    #     op.ttl = 0
    #     entity_store.remove_entity id: rec.id
    #   end
    #   camera.scale = 1 + op.target_scale * (op.duration-op.ttl)/op.duration.to_f
    #   camera.target_x = op.target_x
    #   camera.target_y = op.target_y
    # end

  end
end
