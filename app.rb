require 'gosu'
require 'awesome_print'
# require 'pry'

require_relative 'vec'
require_relative 'components'
require_relative 'prefab'
require_relative 'systems'
require_relative 'entity_manager'
require_relative 'input_cacher'
require_relative 'level'


class PixelMonster < Gosu::Window
  MAX_UPDATE_SIZE_IN_MILLIS = 500
  def initialize
    super(1024,1024,false)

    @entity_manager = EntityManager.new
    @input_cacher = InputCacher.new
    @level_number = (ARGV[0] || 1).to_i - 1
    @num_levels = Dir['./levels/level*.png'].size
    @music = Gosu::Song.new 'music.wav'
    next_level
    build_systems
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
    @level = Level.load(@filename)
    @level.reset! if @level
    @entity_manager = EntityManager.new
    Prefab.level entity_manager: @entity_manager, level: @level
  end

  def build_systems
    @input_mapping_system = InputMappingSystem.new
    @monster_system = MonsterSystem.new
    @rainbow_system = RainbowSystem.new

    @timer_system = TimerSystem.new

    @sound_system = SoundSystem.new

    @particles_emitter_system = ParticlesEmitterSystem.new
    @particles_system = ParticlesSystem.new
    @background_system = BackgroundSystem.new
    @render_system = RenderSystem.new
  end

  def update
    next_level if @level.complete?
    reset_level if @level.failed?
    self.caption = "FPS: #{Gosu.fps} ENTS: #{@entity_manager.num_entities}"

    total_millis = Gosu::milliseconds.to_f

    # ignore the first update
    if @last_millis
      delta = total_millis
      delta -= @last_millis if total_millis > @last_millis
      delta = MAX_UPDATE_SIZE_IN_MILLIS if delta > MAX_UPDATE_SIZE_IN_MILLIS

      mouse_pos = {x: mouse_x, y: mouse_y}
      input_snapshot = @input_cacher.snapshot @last_snapshot, total_millis, mouse_pos
      @last_snapshot = input_snapshot

      @input_mapping_system.update @entity_manager, delta, input_snapshot

      @monster_system.update @entity_manager, delta, input_snapshot
      @rainbow_system.update @entity_manager, delta, input_snapshot

      @timer_system.update @entity_manager, delta, input_snapshot

      @sound_system.update @entity_manager, delta, input_snapshot

      @particles_emitter_system.update @entity_manager, delta, input_snapshot
      @particles_system.update @entity_manager, delta, input_snapshot
      @background_system.update @entity_manager, delta, input_snapshot
    end

    @last_millis = total_millis
  end

  def draw
    @render_system.draw self, @entity_manager
  end

  def button_down(id)
    if id == Gosu::KbP
      ap @entity_manager
    end
    @input_cacher.button_down id
  end

  def button_up(id)
    @input_cacher.button_up id
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
