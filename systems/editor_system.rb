class EditorState
  attr_accessor :current_color, :mouse_x, :mouse_y
end

class EditorSystem
  def initialize(game_store)
    @game_entity_store = game_store
    @changes = []
  end

  def update(entity_store, dt, input, global_events)
    # handle click at x,y
    state = entity_store.first(EditorState)
    unless state
      ed_state = EditorState.new
      ed_state.mouse_x = input.mouse_pos[:x]
      ed_state.mouse_y = input.mouse_pos[:y]
      ed_state.current_color = Gosu::Color::BLUE

      entity_store.add_entity(ed_state)
    end

    state = entity_store.first(EditorState).get(EditorState)
    state.mouse_x = input.mouse_pos[:x]
    state.mouse_y = input.mouse_pos[:y]

    x = input.mouse_pos[:x]
    y = input.mouse_pos[:y]
    level = @game_entity_store.find(Level).first.get(Level)
    map = level.map
    tile_pos = map.world_to_map(x,y)
    snapped_pos = map.map_to_world(tile_pos.x, tile_pos.y)

    if input.pressed?(Gosu::MsRight)
      @changes << [:delete, tile_pos]
      map.tiles[tile_pos.x][tile_pos.y] = nil

      q = Q.must(Boxed).must(Position).with(x: snapped_pos.x, y: snapped_pos.y)
      @game_entity_store.remove_entites(ids: @game_entity_store.query(q).map(&:id))
    end

    if input.pressed?(Gosu::MsLeft)
      @changes << [:add_color_source, tile_pos, state.current_color]

      Prefab.color_source(entity_store: @game_entity_store, x: snapped_pos.x, y: snapped_pos.y, color: state.current_color)
      tile = ColorSourceTile.from_color(state.current_color)
      map.tiles[tile_pos.x][tile_pos.y] = tile
    end
  end
  def save
    # reload level clean
    # apply changes and save
  end

end
