require 'gosu'
require 'awesome_print'
# require 'pry'

require_relative 'gosu_ext'
require_relative 'vec'
require_relative 'components'
require_relative 'prefab'
require_relative 'systems'
require_relative 'world'
require_relative 'entity_manager'
require_relative 'input_cacher'
require_relative 'level'
require_relative 'scoreboard'


class PixelMonster < Gosu::Window
  MAX_UPDATE_SIZE_IN_MILLIS = 500
  def initialize
    super(1024,1024,false)
    @level_number = (ARGV[0] || 1).to_i - 1
    @num_levels = Dir['./levels/level*.png'].size
    @music = Gosu::Song.new 'music.wav'
    @input_cacher = InputCacher.new
    @scoreboard = Scoreboard.new
    build_world

    next_level
  end

  def needs_cursor?
    false
  end

  def next_level
    @music.stop
    @music.play true
    @level_number = @level_number += 1

    @level_number = 1 if @level_number > @num_levels

    @filename = "level#{@level_number}.png"
    reset_level
  end

  def reset_level
    @level = Level.load(file_name: @filename, 
                        number: @level_number, 
                        high_scores: @scoreboard)
    @world.reset! if @world
    @level.reset! if @level
    Prefab.level entity_manager: @world.entity_manager, level: @level
  end

  def build_world
    entity_manager = EntityManager.new
    @world = World.new entity_manager, [
      InputMappingSystem.new,
      MonsterSystem.new,
      RainbowSystem.new,
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

  def update
    if @level.complete?
      update_scoreboard!(@level)
      next_level 
    end
    reset_level if @level.failed?
    self.caption = "FPS: #{Gosu.fps} ENTS: #{@world.entity_manager.num_entities}"

    total_millis = Gosu::milliseconds.to_f

    # ignore the first update
    if @last_millis
      delta = total_millis
      delta -= @last_millis if total_millis > @last_millis
      delta = MAX_UPDATE_SIZE_IN_MILLIS if delta > MAX_UPDATE_SIZE_IN_MILLIS

      mouse_pos = {x: mouse_x, y: mouse_y}
      input_snapshot = @input_cacher.snapshot @last_snapshot, total_millis, mouse_pos
      @last_snapshot = input_snapshot

      @world.update delta, input_snapshot
    end

    @last_millis = total_millis
  end

  def draw
    @render_system.draw self, @world.entity_manager
  end

  def button_down(id)
    if id == Gosu::KbP
      ap @world.entity_manager
    end
    @input_cacher.button_down id
  end

  def button_up(id)
    @input_cacher.button_up id
  end

  def update_scoreboard!(level)
    @scoreboard.completed_level level: level, number: @level_number
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
