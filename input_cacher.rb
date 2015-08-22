require 'set'

class InputCacher
  attr_reader :down_ids
  attr_accessor :mouse_pos

  def initialize(down_ids = nil, mouse_pos = nil)
    @down_ids = down_ids || Set.new
    @mouse_pos = mouse_pos
  end

  def button_down(id)
    @down_ids.add id
  end

  def button_up(id)
    @down_ids.delete id
  end

  def down?(id)
    @down_ids.include? id
  end

  def snapshot
    InputCacher.new(@down_ids.dup, @mouse_pos.dup).freeze
  end
end


