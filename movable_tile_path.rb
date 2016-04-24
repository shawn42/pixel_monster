
class MovableTilePath
  attr_reader :path_steps

  def initialize(path_steps)
    @path_steps = path_steps
    @current_index = 0
  end

  def next
    @current_index += 1
    if @current_index >= @path_steps.size
      @current_index = 0
    end
    current
  end

  def current
    @path_steps[@current_index]
  end

  def self.build(path_locs, start_loc, start_dir, rule)
    path_steps = PathWalker.build_path_steps(path_locs,start_loc,start_dir,rule)
    return MovableTilePath.new(path_steps)
  end
end

