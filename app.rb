require 'gosu'
require 'game_ecs'
require 'awesome_print'
require 'fileutils'
# require 'pry'

require_relative 'core_ext'
require_relative 'gosu_ext'
require_relative 'vec'
require_relative 'components'
require_relative 'prefab'
require_relative 'systems/systems.rb'
require_relative 'world'
require_relative 'input_cacher'
require_relative 'level'
require_relative 'scoreboard'


Q = GameEcs::Query
class PixelMonster < Gosu::Window
  MAX_UPDATE_SIZE_IN_MILLIS = 500
  def initialize
    super(1024,1024,false)
    level_arg = ARGV[0] || "1"
    if level_arg.start_with? "http"
      level_name = level_arg.split('/').last
      require 'open-uri'

      FileUtils.mkdir_p 'custom_levels'
      @custom_level = File.join('custom_levels', "#{level_name}")
      IO.copy_stream(open(level_arg), @custom_level)
    else
      @level_number = level_arg.to_i - 1
    end
    @num_levels = Dir['./levels/level*.png'].size
    @music_files = Dir['./music/*.mp3']
    @input_cacher = InputCacher.new
    @scoreboard = Scoreboard.new
    @last_millis = Gosu::milliseconds.to_f
    build_world

    next_level
  end

  def needs_cursor?
    false
  end

  def update
    self.caption = "FPS: #{Gosu.fps} ENTS: #{@entity_store.num_entities}"
    update_level!

    delta = relative_delta
    snapshot = take_input_snapshot
    @last_update = @world.update @entity_store, delta, snapshot
    # TODO use last_update[:global_events] for something: like level changes?
  end

  def draw
    @render_system.draw self, @entity_store
  end

  def draw_box(x1,y1,x2,y2,c,z)
    draw_line x1, y1, c, x2, y1, c, z
    draw_line x2, y1, c, x2, y2, c, z
    draw_line x2, y2, c, x1, y2, c, z
    draw_line x1, y2, c, x1, y1, c, z
  end

  def button_down(id)
    @input_cacher.button_down id
  end

  def button_up(id)
    @input_cacher.button_up id
  end
  private

  def next_level
    @music.stop if @music

    if @custom_level.nil?
      @level_number = @level_number += 1
      @level_number = 1 if @level_number > @num_levels
      @filename = File.join('levels', "level#{@level_number}.png")
    else
      @level_number = :custom
      @filename = @custom_level
    end

    reset_level

    avg_rgb = @level.map.average_color
    hue = calc_hue(rgb: avg_rgb)
    index = hue * @music_files.size / 360
    file_name = @music_files[index.floor]
    @music = Gosu::Song.new file_name
    @music.volume = 0.1
    @music.play true
  end

  def calc_hue(rgb:)
    g = rgb.green / 255.0
    r = rgb.red / 255.0
    b = rgb.blue / 255.0
    cmax = [r,g,b].max
    cmin = [r,g,b].min
    delta = cmax-cmin

    hue = if cmax == r
        (g-b)
      elsif cmax == g
        2 + (b-r)
      else
        4 + (r-g)
      end
    hue /= delta
    hue *= 60
    hue %= 360
    hue
  end

  def reset_level
    @level = Level.load(file_name: @filename, 
                        number: @level_number, 
                        high_scores: @scoreboard)
    @entity_store.clear! if @entity_store
    @level.reset! if @level
    Prefab.level entity_store: @entity_store, level: @level
    Prefab.camera entity_store: @entity_store, scale: 1, x: 512, y: 512
  end

  def build_world
    @entity_store = GameEcs::EntityStore.new
    @world = World.new [
      InputMappingSystem.new,
      CameraSystem.new,
      MonsterSystem.new,
      RainbowSystem.new,
      FadingSystem.new,
      TimerSystem.new,
      TimedSystem.new,
      TimedLevelSystem.new,
      SoundSystem.new,
      ParticlesEmitterSystem.new,
      ParticlesSystem.new,
      BackgroundSystem.new
    ]
    @render_system = RenderSystem.new
  end

  def update_level!
    if @level.complete?
      update_scoreboard!
      next_level 
    end
    reset_level if @level.failed?
  end

  def update_scoreboard!
    # TODO track scoreboard..
    @scoreboard.completed_level level: @level, number: @level_number
  end

  def relative_delta
    total_millis = Gosu::milliseconds.to_f
    delta = total_millis
    delta -= @last_millis if total_millis > @last_millis
    @last_millis = total_millis
    delta = MAX_UPDATE_SIZE_IN_MILLIS if delta > MAX_UPDATE_SIZE_IN_MILLIS
    delta
  end

  def take_input_snapshot
    total_millis = Gosu::milliseconds.to_f

    mouse_pos = {x: mouse_x, y: mouse_y}
    input_snapshot = @input_cacher.snapshot @last_snapshot, total_millis, mouse_pos
    @last_snapshot = input_snapshot
    input_snapshot
  end
end

if $0 == __FILE__
# require 'ruby-prof'
#
# # Profile the code
# RubyProf.start
# at_exit do
#   result = RubyProf.stop
#
#   # Print a flat profile to text
#   printer = RubyProf::FlatPrinter.new(result)
#   printer.print(STDOUT)
#
# end
# require 'stackprof'
# StackProf.run(mode: :cpu, out: './stackprof-cpu-myapp.dump') do
  $window = PixelMonster.new
  $window.show
end
# end
