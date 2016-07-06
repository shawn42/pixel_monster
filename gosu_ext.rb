module Gosu
  class Color
    alias hash gl
    def eql?(other)
      gl == other.gl
    end
  end
end
