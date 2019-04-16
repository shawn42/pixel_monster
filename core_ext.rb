module Enumerable
  def sum
    reduce(&:+)
  end
end
