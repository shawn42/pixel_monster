
class InputMappingSystem
  def update(entity_store, dt, input, global_events)
    $window.close if input.down?(Gosu::KbEscape) || input.down?(Gosu::GpButton8)
    # entity_store.each_entity KeyboardControl, Controls do |rec|
    #   keys, control = rec.components
    #   ent_id = rec.id
    #   control.move_left = input.down?(keys.move_left)
    #   control.move_right = input.down?(keys.move_right)
    #   control.move_up = input.down?(keys.move_up)
    #   control.move_down = input.down?(keys.move_down)
    # end
  end
end
