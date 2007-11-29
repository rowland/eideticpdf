#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-09-30.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

$: << File.dirname(__FILE__) + '/../'
require 'epdfw'

def grid(w, width, height, xoff, yoff, step=1)
  w.path(:stroke => true) do
    # vertical lines
    0.step(width, step) do |x|
      w.move_to(x + xoff, yoff)
      w.line_to(x + xoff, height + yoff)
    end
    # horizontal lines
    0.step(height, step) do |y|
      w.move_to(xoff, y + yoff)
      w.line_to(width + xoff, y + yoff)
    end
  end
end

def inch_grid(w, width=8, height=10, xoff=0.25, yoff=0.5)
  w.page(:units => :in) do |p|
    p.set_font("Helvetica", 10)
    p.print_xy(0.25, 0.25, "Inch Squares")
    grid(p, width, height, xoff, yoff)
  end
end

def cm_grid(w, width=20, height=26, xoff=0.75, yoff=1)
  w.page(:units => :cm) do |p|
    p.set_font("Helvetica", 10)
    p.print_xy(0.5, 0.5, "Centimeter Squares")
    grid(p, width, height, xoff, yoff)
  end
end

def dp_grid(w, width=8000, height=10000, xoff=250, yoff=500)
  # set custom point scale
  EideticPDF::UNIT_CONVERSION[:dp] = 0.072
  w.start_page(:units => :dp)
  w.set_font("Helvetica", 10)
  w.print_xy(250, 250, "Dave Points Squares")
  grid(w, width, height, xoff, yoff, 1000)
  w.end_page
end

def pt_units(w)
  w.page(:units => :pt, :orientation => :portrait) do |p|
    p.rectangle(1,1,p.page_width-3, p.page_height-2)
    p.print_xy(5, 5, "Point Units")

    y = 24; size = 12
    while y < 700
      p.set_font("Helvetica", size)
      p.print_xy(5, y, "Size: #{size}, y: #{y}")
      y += size; size += 12
    end
  end
end

def circles_and_rectangles(w)
  w.start_page(:units => :in)
  w.print_xy(0.5, 0.5, "Circles and Rectangles")
  w.rectangle(1, 1, 6.5, 9)
  w.rectangle(2, 2, 4.5, 7)
  w.circle(4.25, 5.5, 3.25)
  w.circle(4.25, 5.5, 2.25)
  w.end_page
end

def font_names(w)
  w.page(:units => :cm) do |p|
    p.move_to(1, 1)
    p.type1_font_names.each do |font_name|
      p.set_font(font_name, 12)
      p.puts(font_name)
    end
  end
end

def print_text(w)
  w.start_page(:units => :cm)
  w.move_to(1, 1)
  w.set_font("Helvetica", 12)
  w.print("Print Text")

  # test vertical text alignment
  w.move_to(1, 3); w.line_to(20,3)
  w.move_to(1, 3)

  w.v_text_align = :base
  w.print("v_text_align = ")
  w.v_text_align = :below
  w.print(":below ")
  w.v_text_align = :base
  w.print(":base ")
  w.v_text_align = :middle
  w.print(":middle ")
  w.v_text_align = :top
  w.print(":top ")
  w.v_text_align = :above
  w.print(":above ")

  w.v_text_align = :top
  w.move_to(1, 5)
  ['Black', 'Blue', 'Brown', 'Crimson', 'Gold', 'Green', 'Gray', 'Indigo'].each do |color|
    w.font_color = color
    w.print "#{color}     "
  end

  w.font_color = 'Black'
  lorem = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
  w.move_to(1, 7); w.line_to(1, 9); w.move_to(20, 7); w.line_to(20, 9) 
  lorem2 = w.paragraph_xy(1.5, 7, lorem, 18, 2)
  w.puts
  w.paragraph(lorem2, 18) unless lorem2.nil?

  w.end_page
end

def print_angled_text(w)
  w.page(:units => :in) do |p|
    p.set_font("Helvetica", 12)
    angle = 0
    while angle < 360
      p.move_to(4.25, 5.5)
      p.print("     Text at #{angle} degrees", :angle => angle)
      angle += 45
    end
  end
end

def landscape_orientation(w)
  w.page(:units => :in, :orientation => :landscape) do |p|
    p.set_font("Times-Roman", 12)
    p.print_xy(0.5, 0.5, "Landscape Orientation")
    p.rectangle(1, 1, p.page_width - 2, p.page_height - 2)
  end
end

def line_widths_and_patterns(w)
  w.page(:units => :cm) do |p|
    p.print_xy(1, 1, "Line Widths and Patterns")
    p.v_text_align = :base

    0.upto(10) do |i|
      p.line_width = "#{i}pt"
      p.move_to(1, 2 + i)
      p.line_to(p.page_width - 5, 2 + i)
      p.print("  #{i} points")
    end

    0.upto(8) do |i|
      pattern = [:solid,:dotted,:dashed][i % 3]
      p.line_width = "#{i}pt"
      p.line_dash_pattern = pattern
      p.move_to(1, 13 + i)
      p.line_to(p.page_width - 5, 13 + i)
      p.print("  #{pattern}")
    end

    p.line_width = "3pt"
    p.line_dash_pattern = :solid
    p.print_xy(1, 22, "Line Colors")
    y = 23.0

    # blue
    p.line_color = 0x0000FF
    p.line_color = [0,0,255]
    p.move_to(1, 23)
    p.line_to(p.page_width - 5, 23)
    p.print("  #{p.line_color}")

    # green
    p.line_color = 0x00FF00
    p.line_color = [0,255,0]
    p.move_to(1, 23.5)
    p.line_to(p.page_width - 5, 23.5)
    p.print("  #{p.line_color}")

    # red
    p.line_color = 0xFF0000
    #p.line_color = [255,0,0]
    p.move_to(1, 24)
    p.line_to(p.page_width - 5, 24)
    p.print("  #{p.line_color}")

    # fuchsia
    p.line_color = [0xFF, 0, 0xFF]
    p.move_to(1, 24.5)
    p.line_to(p.page_width - 5, 24.5)
    p.print("  #{p.line_color}")

    # yellow
    p.line_color = [0xFF, 0xFF, 0]
    p.move_to(1, 25)
    p.line_to(p.page_width - 5, 25)
    p.print("  #{p.line_color}")

    # black custom pattern
    EideticPDF::LINE_PATTERNS[:dotted2] = [1, 10]
    p.line_color = 0
    p.line_dash_pattern = :dotted2
    p.move_to(1, 26)
    p.line_to(p.page_width - 5, 26)
    p.print("  (custom pattern)")
  end
end

def arcs(w)
  w.page(:units => :in) do |p|
    p.print_xy(0.5, 0.5, "Arcs")

    x1, x2, y1, y2 = 4.0, 4.5, 2.25, 2.75
    s = 0
    [0.75, 1.00, 1.25].each do |r|
      p.arc(x2, y1, r, s, s+90, true)
      p.arc(x1, y1, r, s+90, s+180, true)
      p.arc(x1, y2, r, s+180, s+270, true)
      p.arc(x2, y2, r, s+270, s+360, true)
    end

    x1, x2, x3, y1, y2, y3 = 4.0, 4.25, 4.5, 8.25, 8.5, 8.75
    s = 45
    [0.75, 1.00, 1.25].each do |r|
      p.arc(x2, y1, r, s, s+90, true)
      p.arc(x1, y2, r, s+90, s+180, true)
      p.arc(x2, y3, r, s+180, s+270, true)
      p.arc(x3, y2, r, s+270, s+360, true)
    end
  end
end

def filled_rectangles(w)
  page_no = 0
  rows, cols = 18, 3
  left, top = 0.75, 1.0
  col_width, row_height, label_width = 2.0, 0.5, 1.25
  names = w.named_colors.keys.sort
  lists = []
  while names.size > 0
    lists << names.slice!(0, rows)
  end
  pages = []
  while lists.size > 0
    pages << lists.slice!(0, cols)
  end
  pages.each_with_index do |page, page_index|
    w.start_page(:units => :in)
    w.set_font("Helvetica", 10)
    w.print_xy(0.5, 0.5, "Filled Rectangles with Named Colors - #{page_index + 1}")
    w.line_height = 1.3
    page.each_with_index do |list, list_index|
      list.each_with_index do |name, name_index|
        w.move_to(left + list_index * col_width, top + name_index * row_height)
        w.puts(name.scan(/[A-Z][a-z]*/))
        w.fill_color = name
        w.rectangle(left + list_index * col_width + label_width, top + name_index * row_height, 0.5, 0.4, :fill => true)
      end
    end
    w.end_page
  end
end

def ellipses(w)
  w.page(:units => :in, :orientation => :portrait) do |p|
    p.print_xy(0.5, 0.5, "Ellipses")
    p.ellipse(4.25, 5.5, 3.75, 3.25)
    p.ellipse(4.25, 5.5, 3.75, 4.5)
    p.ellipse(4.25, 5.5, 3, 2, :rotation => 45)
  end
end

def filled_shapes(w)
  x1, x2, x3 = 0.75, 3.25, 5.75
  y1, y2, y3, y4 = 1.0, 3.5, 6.0, 8.5
  w.page(:units => :in) do |p|
    p.print_xy(0.5, 0.5, "Filled Shapes")
    p.line_color = 'Black'
    p.fill_color = 'LightSteelBlue'

    # empty rectangle w/ border
    p.rectangle(x1, y1, 2, 2)
    # filled rectangle w/ border
    p.rectangle(x1, y2, 2, 2, :fill => true)
    # filled rectangle w/o border
    p.rectangle(x1, y3, 2, 2, :fill => true, :border => false)

    # empty circle w/ border
    p.circle(x2 + 1, y1 + 1, 1)
    # filled circle w/ border
    p.circle(x2 + 1, y2 + 1, 1, :fill => true)
    # filled circle w/o border
    p.circle(x2 + 1, y3 + 1, 1, :fill => true, :border => false)

    # empty ellipse w/ border
    p.ellipse(x3 + 1, y1 + 1, 0.75, 1)
    # filled ellipse w/ border
    p.ellipse(x3 + 1, y2 + 1, 0.75, 1, :fill => true)
    # filled ellipse w/o border
    p.ellipse(x3 + 1, y3 + 1, 0.75, 1, :fill => true, :border => false)

    # filled rectangles w/ borders
    p.fill_color = 'LightSteelBlue'
    p.rectangle(x1, y4, 2, 2, :fill => true)
    p.fill_color = 'White'
    p.rectangle(x1 + 0.5, y4 + 0.5, 1, 1, :fill => true)
    # filled circles w/ borders
    p.fill_color = 'LightSteelBlue'
    p.circle(x2 + 1, y4 + 1, 1, :fill => true)
    p.fill_color = 'White'
    p.circle(x2 + 1, y4 + 1, 0.5, :fill => true)
    # filled ellipses w/ borders
    p.fill_color = 'LightSteelBlue'
    p.ellipse(x3 + 1, y4 + 1, 0.75, 1, :fill => true)
    p.fill_color = 'White'
    p.ellipse(x3 + 1, y4 + 1, 0.25, 0.5, :fill => true)
  end
end

def compound_paths(w)
  w.page(:units => :in) do |p|
    p.print_xy(0.5, 0.5, "Compound Paths")
    p.fill_color = 'LightSteelBlue'

    # filled rectangle w/ only 3 borders
    p.path
    p.move_to(1, 1)
    p.line_to(3, 1)
    p.line_to(3, 2)
    p.line_to(1, 2)
    p.fill_and_stroke

    p.path(:fill => true, :stroke => true) do
      p.rectangle(1, 3, 3, 3, :path => true)
      p.rectangle(1.5, 3.5, 1, 1, :path => true, :reverse => true)
      p.rectangle(2.75, 4.75, 1, 1, :path => true, :reverse => true)
    end

    p.path(:fill => true, :stroke => true) do
      p.circle(2.5, 8.5, 1.5)
      p.circle(2.5, 8.5, 0.5, :reverse => true)
    end

    p.path(:fill => true, :stroke => true) do
      p.ellipse(6.5, 2.5, 1.5, 2)
      p.ellipse(6.5, 2.5, 1, 1.5, :reverse => true)
    end

    p.path(:fill => true, :stroke => true) do
      p.rectangle(5, 6, 3, 4, :corners => [0.5])
      p.rectangle(5.5, 6.5, 2, 3, :corners => [1, 0.5, 1, 0.5, 0.5, 1, 0.5, 1], :reverse => true)
    end
  end
end

def pies(w)
  w.page(:units => :in) do |p|
    p.print_xy(0.5, 0.5, "Pies")
    p.line_color = 0

    p.path(:fill => true, :stroke => true) do
      p.fill_color = 'Crimson'
      p.pie(4, 3, 2, 0, 90)
      p.circle(4.75, 2.25, 0.5, :reverse => true)
    end
    p.pie(4, 3, 2, 90, 135, :fill => 'DarkOrange')
    p.pie(4, 3, 2, 135, 225, :fill => 'Orchid')
    p.pie(4, 3, 2, 225, 270, :fill => 'Gold')
    
    p.pie(4.25, 3.25, 2, 270, 360, :fill => 'MediumSeaGreen')

    p.print_xy(0.5, 6, "Arches")
    p.arch(4, 8, 1.5, 2, 0, 90, :fill => 'MediumSeaGreen')
    p.arch(4, 8, 1, 1.5, 90, 180, :fill => 'Crimson')
    p.arch(4, 8, 0.5, 1, 0, 90, :fill => 'DarkOrange')
    p.arch(4, 8, 0, 0.5, 90, 180, :fill => 'Gold')
  end
end

def polygons(w)
  w.page(:units => :in) do |p|
    p.print_xy(0.5, 0.5, "Polygons")
    p.fill_color = 'LightSteelBlue'

    x1, x2, x3 = 1.75, 4.25, 6.75
    y1, y2, y3, y4 = 2, 4.5, 7, 9.5
    r = 1

    p.polygon(x1, y1, r, 3, :fill => true)
    p.polygon(x2, y1, r, 4, :fill => true, :border => 'Blue')
    p.polygon(x3, y1, r, 5, :fill => true, :border => 'ForestGreen')
    p.polygon(x1, y2, r, 6, :fill => true, :border => 'Crimson')
    p.polygon(x2, y2, r, 7, :fill => true, :border => 'Gray')
    p.polygon(x3, y2, r, 8, :fill => true)

    w.polygon(x1, y3, r, 3, :fill => 'DarkSlateGray', :rotation => 360.0 / 6)
    w.polygon(x2, y3, r, 4, :fill => 'DarkTurquoise', :rotation => 360.0 / 8)
    w.polygon(x3, y3, r, 5, :fill => 'DeepSkyBlue', :rotation => 360.0 / 10)
    w.polygon(x1, y4, r, 6, :fill => 'ForestGreen', :rotation => 360.0 / 12)
    w.polygon(x2, y4, r, 7, :fill => 'DarkSlateBlue', :rotation => 360.0 / 14)
    w.polygon(x3, y4, r, 8, :fill => true, :rotation => 360.0 / 16)
  end
end

def stars(w)
  w.page(:units => :in) do |p|
    p.print_xy(0.5, 0.5, "Stars")
    p.fill_color = 'LightSteelBlue'

    x1, x2, x3 = 1.75, 4.25, 6.75
    y1, y2, y3, y4 = 2, 4.5, 7, 9.5
    r = 1

    p.star(x1, y1, r, 5, :fill => true)
    p.star(x2, y1, r, 6, :fill => true, :border => 'Blue')
    p.star(x3, y1, r, 7, :fill => true, :border => 'ForestGreen')
    p.star(x1, y2, r, 8, :fill => true, :border => 'Crimson')
    p.star(x2, y2, r, 9, :fill => true, :border => 'Gray')
    p.star(x3, y2, r, 10, :fill => true)

    w.star(x1, y3, r, 5, :fill => 'DarkSlateGray', :rotation => 360.0 / 10)
    w.star(x2, y3, r, 6, :fill => 'DarkTurquoise', :rotation => 360.0 / 12)
    w.star(x3, y3, r, 7, :fill => 'DeepSkyBlue', :rotation => 360.0 / 14)
    w.star(x1, y4, r, 8, :fill => 'ForestGreen', :rotation => 360.0 / 16)
    w.star(x2, y4, r, 9, :fill => 'DarkSlateBlue', :rotation => 360.0 / 18)
    w.star(x3, y4, r, 10, :fill => true, :rotation => 360.0 / 20)
  end
end

start = Time.now
docw = EideticPDF::DocumentWriter.new

docw.doc(:font => { :name => 'Courier', :size => 10 }) do |w|
  stars(w)
  polygons(w)
  pies(w)
  compound_paths(w)
  filled_shapes(w)
  circles_and_rectangles(w)
  ellipses(w)
  filled_rectangles(w)
  line_widths_and_patterns(w)
  print_text(w)
  landscape_orientation(w)
  print_angled_text(w)
  arcs(w)
  pt_units(w)
  cm_grid(w)
  inch_grid(w)
  dp_grid(w)
  font_names(w)
end

File.open("test.pdf","w") { |f| f.write(docw) }

elapsed = Time.now - start
puts "Elapsed: #{(elapsed * 1000).round} ms"
`open test.pdf`
#print docw
