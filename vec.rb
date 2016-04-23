# terrible vector class  =P
def vec(x,y)
  Vec.new(x:x,y:y)
end
class Vec
  attr_accessor :x, :y

  def initialize(x:0,y:0)
    @x = x
    @y = y
  end

  def +(other)
    [x+other.x,y+other.y]
  end

  def unit
    m = Math.sqrt(x*x+y*y)
    [x/m,y/m]
  end

  def to_s
    "Vec: [#{x},#{y}]"
  end
end
