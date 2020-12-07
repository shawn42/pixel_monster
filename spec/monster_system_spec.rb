
require 'gosu'
require 'game_ecs'
require 'awesome_print'
require 'fileutils'

require_relative '../core_ext'
require_relative '../gosu_ext'
require_relative '../vec'
require_relative '../input_cacher'
require_relative '../components'
require_relative '../prefab'
require_relative '../systems/systems'
require_relative '../level'
require_relative '../scoreboard'
RSpec.describe MonsterSystem do
  describe '#update' do
    it 'does not blow up' do
      down_ids = []
      mouse_info = {}
      previous_snapshot = nil
      global_events = []
      input = InputSnapshot.new(previous_snapshot, 1_000, down_ids, mouse_info).freeze

      delta = 12
      store = GameEcs::EntityStore.new
      level = Level.load(file_name: 'spec/fixtures/level1.png', 
                        number: 99_999, 
                        high_scores: Scoreboard.new)
      Prefab.level(entity_store: store, level: level)

      subject.update(store, delta, input, global_events)
    end


  end

  describe '#boxes_touch?' do
    context 'with boxes touching on left side' do
      it 'is true' do
        center_a = Position.new(2, 2)
        box_a = Boxed.new(2,2)
        center_b = Position.new(4, 2)
        box_b = Boxed.new(2,2)
        expect(subject.send(:boxes_touch?, center_a, box_a, center_b, box_b)).to be(true)
      end
    end
  end
end
