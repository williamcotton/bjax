require 'ruby2ruby'

class Proc
  
  def _dump(depth = 0)
    l = self
    c = Class.new
    c.class_eval do
      define_method :s, &l
    end
    s = Ruby2Ruby.translate(c, :s)
    'proc {' + s[8..-5] + '}'
  end
  
  def self._load(str)
    eval(str)
  end
  
end