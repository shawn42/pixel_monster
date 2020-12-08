
class RenderSystem

  def initialize
    @font_cache = {}
    @color_cache = {}
  end

  def get_cached_font(font:,size:)
    @font_cache[font] ||= {}
    opts = {}
    opts[:name] if font if font
    @font_cache[font][size] ||= Gosu::Font.new size, opts
  end

  def fade(color, percent:)
    @color_cache[color] ||= {}
    c = Gosu::Color.rgba(color.red, color.green, color.blue, 
                         (color.alpha * percent / 100.0).round)
    @color_cache[color][percent] ||= c
  end

  def draw_labels(entity_store)
    entity_store.each_entity Label, Position do |rec|
      label, pos = rec.components
      font = get_cached_font font: label.font, size: label.size
      font.draw_markup(label.text, pos.x, pos.y, pos.z)
    end
  end

  def draw_color_helper_hud(hud_rec, map, target)
    if hud_rec

      mon, pos, color, d = hud_rec.components
      c = color.color
      x = 20
      y = 1024-10
      full_h = 60
      z = 3
      exit_color = map.exit_color

      bg_color = Gosu::Color.rgba(255,255,255,40)
      target.draw_rect( x-5, y-full_h-10, 60+10, full_h+10, bg_color, z)


      r = Gosu::Color::RED
      g = Gosu::Color::GREEN
      b = Gosu::Color::BLUE
      rr = fade(r, percent: 20)
      gg = fade(g, percent: 20)
      bb = fade(b, percent: 20)

      h = (exit_color.red / 255.0 * full_h + 1).round
      target.draw_quad(x, y, rr, x, y-h, rr, x+20, y-h, rr, x+20, y, rr, z)
      h = (c.red / 255.0 * full_h).round
      target.draw_quad(x+5, y, r, x+5, y-h, r, x+15, y-h, r, x+15, y, r, z)

      h = (exit_color.green / 255.0 * full_h + 1).round
      target.draw_quad(x+20, y, gg, x+20, y-h, gg, x+40, y-h, gg, x+40, y, gg, z)
      h = (c.green / 255.0 * full_h).round
      target.draw_quad(x+25, y, g, x+25, y-h, g, x+35, y-h, g, x+35, y, g, z)

      h = (exit_color.blue / 255.0 * full_h + 1).round
      target.draw_quad(x+40, y, bb, x+40, y-h, bb, x+60, y-h, bb, x+60, y, bb, z)
      h = (c.blue / 255.0 * full_h).round
      target.draw_quad(x+45, y, b, x+45, y-h, b, x+55, y-h, b, x+55, y, b, z)

      target.draw_box( x-5, y-full_h-10, x-5+60+10, y, Gosu::Color::WHITE, z)
    end

  end

  TILE_WIDTH = 32
  WINDOW_WIDTH = WINDOW_HEIGHT = 1024

  def draw(target, entity_store)
    # ignore for now, this is for zooming in on exit when first triggered
    camera = entity_store.first(Camera, Position)
    cam, cam_pos = camera.components

    # TODO update render locs and sizes of UI elements for total w/h

    level = entity_store.first(Level).get(Level)
    map = level.map

    map_width_pixels_needed = level.width * TILE_WIDTH
    map_height_pixels_needed = level.height * TILE_WIDTH
    x_scale = y_scale = 1
    x_offset = y_offset = 0

    monster = entity_store.find(Monster, Position).first
    monster_id = monster ? monster.id : nil
    monster_pos = monster&.components&.first

    y_offset = x_offset = 0

    if cam.mode == Camera::AUTOFIT
      if map_height_pixels_needed > WINDOW_HEIGHT ||
        map_width_pixels_needed > WINDOW_WIDTH
        w_scale = WINDOW_WIDTH.to_f / map_width_pixels_needed
        h_scale = WINDOW_HEIGHT.to_f / map_height_pixels_needed
        if h_scale < w_scale
          x_scale = y_scale = h_scale
          x_offset = (map_width_pixels_needed.to_f / h_scale - WINDOW_WIDTH) / 2
        else
          x_scale = y_scale = w_scale
          y_offset = (map_height_pixels_needed.to_f / w_scale - WINDOW_HEIGHT) / 2
        end
      else
        x_offset = WINDOW_WIDTH / 2 - cam_pos.x
        y_offset = WINDOW_HEIGHT / 2 - cam_pos.y
      end

    end

    around_x = around_y = 0
    target.scale(x_scale, y_scale, around_x, around_y) do
      target.translate(x_offset, y_offset) do
      draw_labels entity_store

    entity_store.each_entity Position, JoyColor, Boxed do |rec|
      pos, color, boxed = rec.components
      ent_id = rec.id
      y_off = (boxed.squish_y_amount * boxed.squish_y_dir / 2.0)#.floor
      y_squish = (boxed.squish_y_amount / 2.0)#.floor
      half_y_squish = y_squish / 2.0

      x_squish = (boxed.squish_x_amount / 2.0)#.floor
      x_dir = boxed.squish_x_dir
      squish_right = x_dir > 0 
      squish_left = x_dir < 0 

      c1 = c2 = c3 = c4 = color.color
      x1 = pos.x - boxed.width - half_y_squish + (squish_right ? x_squish : 0)
      y1 = pos.y - boxed.height + y_off + y_squish - (squish_left ? 3 * x_squish : x_squish)

      x2 = pos.x + boxed.width + half_y_squish + (squish_left ? -x_squish : 0)
      y2 = pos.y - boxed.height + y_off + y_squish - (squish_right ? 3 * x_squish : x_squish)

      x3 = x2 
      y3 = pos.y + boxed.height + y_off - y_squish

      x4 = x1
      y4 = y3
      if monster_id == ent_id
        c = Gosu::Color::WHITE
        target.draw_quad(x1-1, y1-1, c, x2+1, y2-1, c, x3+1, y3+1, c, x4-1, y4+1, c, pos.z)
      end
      target.draw_quad(x1, y1, c1, x2, y2, c2, x3, y3, c3, x4, y4, c4, pos.z)
    end

    entity_store.each_entity Position, JoyColor, Border do |rec|
      pos, color, border = rec.components
      c1 = c2 = c3 = c4 = color.color
      x1 = pos.x - border.width
      y1 = pos.y - border.height
      x2 = pos.x + border.width
      y2 = y1
      x3 = x2
      y3 = pos.y + border.height
      x4 = x1
      y4 = y3

      target.draw_quad(x1, y1, c1, x2, y2, c2, x3, y3, c3, x4, y4, c4, pos.z)
    end

    hud = entity_store.find(Monster, Position, JoyColor, Debug).first

    draw_color_helper_hud hud, map, target

    death_box_recs = entity_store.find(Position, Boxed, Death)
    if death_box_recs[0]
      # all death boxes are the same size..
      pos, death_box, death = death_box_recs[0].components
      w = death_box.width
      h = death_box.height
      x = 0
      y = 0

      glitch_img = target.record(32,32) do
        n = 50

        n.times do
          rx = rand(x-w-4..x+w)
          ry = rand(y-h-4..y+h)
          rw = rand(2..5)
          rh = rand(2..5)
          rc = Gosu::Color.rgba(rand(200)+50,rand(200)+50,rand(200)+50,rand(35)+220)
          z = 1
          target.draw_quad(rx, ry, rc, rx+rw, ry, rc, rx+rw, ry+rh, rc, rx, ry+rh, rc, z)
        end
      end

      entity_store.each_entity(Position, Boxed, Death) do |rec|
        pos, death_box, death = rec.components

        x = pos.x
        y = pos.y
        z = 4
        glitch_img.draw x, y, z
      end
    end

    ed = entity_store.first(EditorState)
    if ed
      ed = ed.get(EditorState)
      target.draw_box(ed.mouse_x-1, ed.mouse_y-1, ed.mouse_x+1, ed.mouse_y+1, ed.current_color, 99_999)
    end

    end
    end
  end
end
