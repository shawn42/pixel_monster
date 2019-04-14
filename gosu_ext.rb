module Gosu
  class Color
    alias hash gl
    def eql?(other)
      gl == other.gl
    end
    def to_s
      "RGBA: #{red}-#{green}-#{blue}-#{alpha}"
    end
    def info
      [red,green,blue,alpha].inspect
    end
  end

  class Gosu::Image
    def get_pixel(x, y)
      return nil if x < 0 or x >= width or y < 0 or y >= height
      @to_blob ||= to_blob
      result = @to_blob[(y * width + x) * 4, 4].unpack("C*")
      Gosu::Color.rgba(*result)
    end
  end
end
