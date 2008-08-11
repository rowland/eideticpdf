require 'rubygems'
require 'epdfdw'

writer = EideticPDF::DocumentWriter.new

writer.doc do |w|
  w.page do|p|
    p.puts_xy(72, 72, "Hello, World.")
  end
end

File.open("life_cycle.pdf","w") { |f| f.write(writer.to_s) }
