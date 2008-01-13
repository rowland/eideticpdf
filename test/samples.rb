#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-12-09.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

$: << File.dirname(__FILE__) + '/../'
require 'epdfdw'

start = Time.now
docw = EideticPDF::DocumentWriter.new

docw.doc(
  :font => { :name => 'Times-Roman', :size => 12 },
  :orientation => :landscape,
  :pages_up => [2, 1],
  :unscaled => true,
  :units => :in,
  :margins => 0.25) do |w|
  # Text
  w.puts "Some really profound text in Times-Roman."
  w.font 'Helvetica'
  w.puts "Some really profound text in Helvetica."
  w.font_size 16
  w.puts "Larger text."
  w.line_dash_pattern :dotted
  w.move_to(5.25, 0); w.line_to(5.25, w.canvas_height)

  w.new_page
  w.font 'Courier', 10
  w.puts %q/w.puts "Some really profound text in Times-Roman."/
  w.puts %q/w.font 'Helvetica'/
  w.puts %q/w.puts "Some really profound text in Helvetica."/
  w.puts %q/w.font_size 16/
  w.puts %q/w.puts "Larger text."/

  # Star
  w.new_page
  w.star 2.5, 2.5, 1, 5, :border => 'ForestGreen', :fill => 'DeepSkyBlue'
  w.line_dash_pattern :dotted
  w.move_to(5.25, 0); w.line_to(5.25, w.canvas_height)

  w.new_page
  w.puts %q/w.star 2.5, 2.5, 1, 5, :border => 'ForestGreen', :fill => 'DeepSkyBlue'/
end

File.open("samples.pdf","w") { |f| f.write(docw) }

elapsed = Time.now - start
puts "Elapsed: #{(elapsed * 1000).round} ms"
`open samples.pdf`
