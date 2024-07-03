module Enumerable
  def sum
    reduce(&:+)
  end
end

class File
  singleton_class.send(:alias_method, :exists?, :exist?)
end
