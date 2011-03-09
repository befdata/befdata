

#!/usr/bin/ruby;
#!http://ruby.brian-amberg.de/editierdistanz/browse/editierdistanz-dynamic-rb.html


  class DistanceTable
    def initialize(m, n)
      @t = Array.new(m) { Array.new(n) { nil } }
    end
   
    def to_s
      @t.map{ |row| row.join(" ") }.join("\n")
    end
   
    def [](i, j)
      return j+1 if i < 0
      return i+1 if j < 0
      @t[i][j]
    end
   
    def []=(i, j, v)
      @t[i][j] = v
    end
  end
   
  def edit_distance(a, b)  
    m = a.length
    n = b.length
    distances = DistanceTable.new(m, n)
   
    for i in 0...m
      for j in 0...n
        distances[i,j] = [
          distances[i-1, j  ] + 1, 
          distances[i,   j-1] + 1, 
          distances[i-1, j-1] + (a[i] == b[j] ? 0 : 1)
        ].min
      end
    end
   
    distances[m-1, n-1]
  end
   
  if ARGV.length != 2
    puts "Usage: editierdistanz WORT_1 WORT_2"
  else
    puts edit_distance(ARGV[0], ARGV[1])
  end

