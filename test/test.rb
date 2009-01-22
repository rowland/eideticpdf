#!/usr/bin/env ruby
# encoding: ASCII-8BIT
#
#  Created by Brent Rowland on 2007-09-30.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

$: << File.dirname(__FILE__) + '/../'
require 'epdfdw'

TestImg = File.join(File.dirname(__FILE__), 'testimg.jpg')
BuiltInFonts = false
LOREM = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

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
    p.font("Helvetica", 10)
    p.print_xy(0.25, 0.25, "Inch Squares", :underline => true)
    grid(p, width, height, xoff, yoff)
  end
end

def cm_grid(w, width=20, height=26, xoff=0.75, yoff=1)
  w.page(:units => :cm) do |p|
    p.font("Helvetica", 10)
    p.print_xy(0.5, 0.5, "Centimeter Squares", :underline => true)
    grid(p, width, height, xoff, yoff)
  end
end

def dp_grid(w, width=8000, height=10000, xoff=250, yoff=500)
  # set custom point scale
  EideticPDF::UNIT_CONVERSION[:dp] = 0.072
  w.open_page(:units => :dp)
  w.font("Helvetica", 10)
  w.print_xy(250, 250, "Dave Points Squares", :underline => true)
  grid(w, width, height, xoff, yoff, 1000)
  w.close_page
end

def pt_units(w)
  w.page(:units => :pt) do |p|
    p.rectangle(1,1,p.page_width-2, p.page_height-2, :clip => true) do
      p.print_xy(5, 5, "Point Units", :underline => true)

      y = 24; size = 12
      while y < 700
        p.font("Helvetica", size)
        p.print_xy(5, y, "Size: #{size}, y: #{y}")
        y += size; size += 12
      end
    end
  end
end

def circles_and_rectangles(w)
  w.open_page(:units => :in)
  w.print_xy(0.5, 0.5, "Circles and Rectangles", :underline => true)
  w.rectangle(1, 1, 6.5, 9)
  w.rectangle(2, 2, 4.5, 7)
  w.circle(4.25, 5.5, 3.25)
  w.circle(4.25, 5.5, 2.25)
  w.close_page
end

def type1_font_names(w)
  w.page(:units => :cm, :margins => [1,2]) do |p|
    p.type1_font_names.sort.each_with_index do |font_name, index|
      p.move_to(p.canvas_width / 2, 0) if index == 40
      encoding = ['Symbol','ZapfDingbats'].include?(font_name) ? 'StandardEncoding' : 'WinAnsiEncoding'
      p.font(font_name, 12, :encoding => encoding)
      p.puts(font_name, :indent => true)
    end
  end
end

def truetype_font_names(w)
  w.page(:units => :cm, :margins => [1,2]) do |p|
    p.truetype_font_names.sort.each_with_index do |font_name, index|
      p.move_to(p.canvas_width / 2, 0) if index == 40
      p.font(font_name, 12, :sub_type => 'TrueType')
      p.puts(font_name)
    end
  end
end

def print_text(w)
  w.open_page(:units => :cm, :margins => 1)
  w.font("Helvetica", 12)
  w.puts("Print Text", :underline => true)
  w.new_line
  w.puts("Version: #{EideticPDF::VERSION}")
  # test vertical text alignment
  w.move_to(0, 3); w.line_to(w.canvas_width, 3)
  w.move_to(0, 3)

  w.v_text_align :base
  w.print("v_text_align = ")
  w.v_text_align :below
  w.print(":below ")
  w.v_text_align :base
  w.print(":base ")
  w.v_text_align :middle
  w.print(":middle ")
  w.v_text_align :top
  w.print(":top ")
  w.v_text_align :above
  w.print(":above ")

  w.v_text_align :top
  w.move_to(0, 5)
  ['Black', 'Blue', 'Brown', 'Crimson', 'Gold', 'Green', 'Gray', 'Indigo'].each do |color|
    w.font_color color
    w.print "#{color}     "
  end

  w.font_color 'Black'
  w.move_to(0, 7); w.line_to(0, 9); w.move_to(w.canvas_width, 7); w.line_to(w.canvas_width, 9) 
  lorem2 = w.paragraph_xy(0.5, 7, LOREM, :width => 18, :height => 2)
  w.puts
  w.paragraph(lorem2, :width => 18) unless lorem2.nil?
  w.puts
  w.paragraph(LOREM, :width => 18, :align => :justify)
  w.puts
  w.paragraph(LOREM, :width => 18, :align => :right)
  w.puts
  w.move_to((w.canvas_width - 10) / 2.0, w.pen_pos.y)
  w.paragraph(LOREM, :width => 10, :align => :center)
  w.close_page
end

def print_angled_text_etc(w)
  w.page(:units => :in) do |p|
    p.font("Helvetica", 12)
    p.print_xy(0.5, 0.5, "Tabs and Angled Text", :underline => true)
    p.move_to(0, 1)
    p.tabs [1, 4.25, 7.5]
    p.tab; p.print "|<--", :align => :left
    p.tab; p.print "-|-", :align => :center
    p.tab; p.print "-->|", :align => :right
    p.tab; p.print "Align: Left", :align => :left
    p.tab; p.print "Align: Center", :align => :center
    p.tab; p.print "Align: Right", :align => :right

    grid(p, 6, 3, 1, 2)
    p.v_text_align :middle
    p.move_to(0, 2)
    p.tabs [1, 2, 3, 4, 5, 6]
    ["Words", "of", "varying", "lengths", "aligned", "left."].each do |word|
      p.tab
      p.print "  #{word}", :align => :left, :angle => 315
    end
    p.move_to(0, 3.5)
    p.tabs [1.5, 2.5, 3.5, 4.5, 5.5, 6.5]
    ["Words", "of", "varying", "lengths", "aligned", "center."].each do |word|
      p.tab
      p.print word, :align => :center, :angle => 45
    end

    p.move_to(0, 5)
    p.tabs [2, 3, 4, 5, 6, 7]
    ["Words", "of", "varying", "lengths", "aligned", "right."].each do |word|
      p.tab
      p.print "#{word}  ", :align => :right, :angle => 315
    end
    
    angle = 0
    while angle < 360
      p.move_to(4.25, 7.5)
      p.print("     Text at #{angle} degrees", :angle => angle, :underline => true)
      angle += 45
    end
  end
end

def landscape_orientation(w)
  w.page(:units => :in, :orientation => :landscape) do |p|
    p.font("Times", 12)
    p.print_xy(0.5, 0.5, "Landscape Orientation", :underline => true)
    p.rectangle(1, 1, p.page_width - 2, p.page_height - 2)
  end
end

def line_widths_and_patterns(w)
  w.page(:units => :cm) do |p|
    p.print_xy(1, 1, "Line Widths and Patterns", :underline => true)
    p.v_text_align :base

    0.upto(10) do |i|
      p.line_width "#{i}pt"
      p.move_to(1, 2 + i)
      p.line_to(p.page_width - 5, 2 + i)
      p.print("  #{i} points")
    end

    0.upto(8) do |i|
      pattern = [:solid,:dotted,:dashed][i % 3]
      p.line_width "#{i}pt"
      p.line_dash_pattern pattern
      p.line_cap_style :round_cap
      p.move_to(1, 13 + i)
      p.line_to(p.page_width - 5, 13 + i)
      p.print("  #{pattern}")
    end

    p.line_width "3pt"
    p.line_dash_pattern :solid
    p.line_cap_style :butt_cap
    p.print_xy(1, 22, "Line Colors")
    y = 23.0

    # blue
    p.line_color 0x0000FF
    p.line_color [0,0,255]
    p.move_to(1, 23)
    p.line_to(p.page_width - 5, 23)
    p.print("  #{p.line_color}")

    # green
    p.line_color 0x00FF00
    p.line_color [0,255,0]
    p.move_to(1, 23.5)
    p.line_to(p.page_width - 5, 23.5)
    p.print("  #{p.line_color}")

    # red
    p.line_color 0xFF0000
    #p.line_color [255,0,0]
    p.move_to(1, 24)
    p.line_to(p.page_width - 5, 24)
    p.print("  #{p.line_color}")

    # fuchsia
    p.line_color [0xFF, 0, 0xFF]
    p.move_to(1, 24.5)
    p.line_to(p.page_width - 5, 24.5)
    p.print("  #{p.line_color}")

    # yellow
    p.line_color [0xFF, 0xFF, 0]
    p.move_to(1, 25)
    p.line_to(p.page_width - 5, 25)
    p.print("  #{p.line_color}")

    # black custom pattern
    EideticPDF::LINE_PATTERNS[:dotted2] = [1, 10]
    p.line_color 0
    p.line_dash_pattern :dotted2
    p.move_to(1, 26)
    p.line_to(p.page_width - 5, 26)
    p.print("  (custom pattern)")
  end
end

def arcs(w)
  w.page(:units => :in) do |p|
    p.print_xy(0.5, 0.5, "Arcs", :underline => true)

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
    w.open_page(:units => :in)
    w.font("Helvetica", 10)
    w.print_xy(0.5, 0.5, "Filled Rectangles with Named Colors - #{page_index + 1}", :underline => true)
    w.line_height 1.3
    page.each_with_index do |list, list_index|
      list.each_with_index do |name, name_index|
        w.move_to(left + list_index * col_width, top + name_index * row_height)
        w.puts(name.scan(/[A-Z][a-z]*/), :indent => true)
        w.fill_color name
        w.rectangle(left + list_index * col_width + label_width, top + name_index * row_height, 0.5, 0.4, :fill => true)
      end
    end
    w.close_page
  end
end

def ellipses(w)
  w.page(:units => :in) do |p|
    p.print_xy(0.5, 0.5, "Ellipses", :underline => true)
    p.ellipse(4.25, 5.5, 3.75, 3.25)
    p.ellipse(4.25, 5.5, 3.75, 4.5)
    p.ellipse(4.25, 5.5, 3, 2, :rotation => 45)
  end
end

def filled_shapes(w)
  x1, x2, x3 = 0.75, 3.25, 5.75
  y1, y2, y3, y4 = 1.0, 3.5, 6.0, 8.5
  w.page(:units => :in) do |p|
    p.print_xy(0.5, 0.5, "Filled Shapes", :underline => true)
    p.line_color 'Black'
    p.fill_color 'LightSteelBlue'

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
    p.fill_color 'LightSteelBlue'
    p.rectangle(x1, y4, 2, 2, :fill => true)
    p.fill_color 'White'
    p.rectangle(x1 + 0.5, y4 + 0.5, 1, 1, :fill => true)
    # filled circles w/ borders
    p.fill_color 'LightSteelBlue'
    p.circle(x2 + 1, y4 + 1, 1, :fill => true)
    p.fill_color 'White'
    p.circle(x2 + 1, y4 + 1, 0.5, :fill => true)
    # filled ellipses w/ borders
    p.fill_color 'LightSteelBlue'
    p.ellipse(x3 + 1, y4 + 1, 0.75, 1, :fill => true)
    p.fill_color 'White'
    p.ellipse(x3 + 1, y4 + 1, 0.25, 0.5, :fill => true)
  end
end

def compound_paths(w)
  w.page(:units => :in) do |p|
    p.print_xy(0.5, 0.5, "Compound Paths", :underline => true)
    p.fill_color 'LightSteelBlue'

    # filled rectangle w/ only 3 borders
    p.path
    p.move_to(1, 1)
    p.line_to(3, 1)
    p.line_to(3, 2)
    p.line_to(1, 2)
    p.fill_and_stroke

    p.path(:fill => true, :stroke => true) do
      p.rectangle(1, 3, 3, 3, :path => true)
      p.rectangle(1.5, 3.5, 1, 1, :reverse => true)
      p.rectangle(2.75, 4.75, 1, 1, :reverse => true)
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
    p.print_xy(0.5, 0.5, "Pies", :underline => true)
    p.line_color 0

    x, y, r = 4, 3, 2
    p.path(:fill => true, :stroke => true) do
      p.fill_color 'Crimson'
      p.pie(x, y, r, 0, 90)
      p.circle(4.75, 2.25, 0.5, :reverse => true)
    end
    p.pie(x, y, r, 90, 135, :fill => 'DarkOrange')
    p.pie(x, y, r, 135, 225, :fill => 'Orchid')
    p.pie(x, y, r, 225, 270, :fill => 'Gold')

    p.pie(x + 0.25, y + 0.25, r, 270, 360, :fill => 'MediumSeaGreen')

    y = 8
    p.print_xy(0.5, 6, "Arches", :underline => true)
    p.arch(x, y, 1.5, 2, 0, 90, :fill => 'MediumSeaGreen')
    p.arch(x, y, 1, 1.5, 90, 180, :fill => 'Crimson')
    p.arch(x, y, 0.5, 1, 0, 90, :fill => 'DarkOrange')
    p.arch(x, y, 0, 0.5, 90, 180, :fill => 'Gold')
  end
end

def polygons(w)
  w.page(:units => :in) do |p|
    p.print_xy(0.5, 0.5, "Polygons", :underline => true)
    p.fill_color 'LightSteelBlue'

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
    p.print_xy(0.5, 0.5, "Stars", :underline => true)
    p.fill_color 'LightSteelBlue'

    x1, x2, x3 = 1.75, 4.25, 6.75
    y1, y2, y3, y4 = 2, 4.5, 7, 9.5
    r = 1

    p.star(x1, y1, r, nil, 5, :fill => true)
    p.star(x2, y1, r, nil, 6, :fill => true, :border => 'Blue')
    p.star(x3, y1, r, nil, 7, :fill => true, :border => 'ForestGreen')
    p.star(x1, y2, r, nil, 8, :fill => true, :border => 'Crimson')
    p.star(x2, y2, r, nil, 9, :fill => true, :border => 'Gray')
    p.star(x3, y2, r, nil, 10, :fill => true)

    w.star(x1, y3, r, nil, 5, :fill => 'DarkSlateGray', :rotation => 360.0 / 10)
    w.star(x2, y3, r, nil, 6, :fill => 'DarkTurquoise', :rotation => 360.0 / 12)
    w.star(x3, y3, r, nil, 7, :fill => 'DeepSkyBlue', :rotation => 360.0 / 14)
    w.star(x1, y4, r, nil, 8, :fill => 'ForestGreen', :rotation => 360.0 / 16)
    w.star(x2, y4, r, nil, 9, :fill => 'DarkSlateBlue', :rotation => 360.0 / 18)
    w.star(x3, y4, r, nil, 10, :fill => true, :rotation => 360.0 / 20)
  end
end

def images(w)
  w.page(:units => :in, :margins => 1) do |p|
    p.print_xy(-0.5, -0.5, "Images", :underline => true)
    # natural size @ current location
    p.print_image_file(TestImg, 0, 0)
    # from a buffer at a specified position and width with auto-height
    img = open(TestImg, EideticPDF::ImageReadMode) { |f| f.read }
    p.print_image(img, 1, 3, 4.5)
    # specified height with auto-width
    p.print_image_file(TestImg, 3.25, 7, nil, 2)
    # specified width and height
    p.print_image_file(TestImg, 0, 8, 1, 1)
  end
end

def clipping(w)
  w.page(:units => :in, :margins => 1) do |p|
    p.print_xy(-0.5, -0.5, "Clipping", :underline => true)
    # grid(p, 6.5, 9, 0, 0)
    p.star(1, 1, 1, nil, 5, :border => false, :clip => true) do
      p.print_image_file(TestImg, 0, 0, nil, 2)
    end
    p.circle(4.5, 1, 1, :clip => true) do
      p.print_image_file(TestImg, 3, 0, 3)
    end
    p.ellipse(1.5, 4, 1.5, 1, :clip => true) do
      p.paragraph_xy(0, 3, LOREM, :width => 3, :height => 2)
    end
    p.path
    p.rectangle(0, 6, 4.5, 3, :corners => [1])
    p.clip do
      p.print_image_file(TestImg, 0, 6, nil, 3)
    end
    
    p.path
    p.circle(4.5, 3.5, 0.3)
    p.circle(5.5, 3.5, 0.3)
    p.circle(5, 4, 0.2)
    p.arch(5, 4, 0.5, 0.9, 210, 330)
    p.clip do
      p.print_image_file(TestImg, 3.5, 3, 3)
    end
  end
end

def text_clipping(w)
  w.page(:units => :in, :margins => 1) do |p|
    p.print_xy(-0.5, -0.5, "Text Clipping", :underline => true)
    # grid(p, 6.5, 9, 0, 0)
    p.font('Helvetica', 144, :weight => 'Bold')
    p.print_xy(0.25, 0.5, "ROSE", :clip => true, :stroke => true) do
      p.print_image_file(TestImg, 0, 0, 6.5)
    end
  end
end

def text_encodings(w)
  fonts = [
    ['Helvetica', 'WinAnsiEncoding'], 
    ['Helvetica', 'ISO-8859-1'], 
    ['Helvetica', 'ISO-8859-2'], 
    ['Helvetica', 'ISO-8859-3'], 
    ['Helvetica', 'ISO-8859-4'], 
    ['Helvetica', 'ISO-8859-7'], 
    ['Helvetica', 'ISO-8859-9'], 
    ['Helvetica', 'ISO-8859-10'], 
    ['Helvetica', 'ISO-8859-13'], 
    ['Helvetica', 'ISO-8859-14'], 
    ['Helvetica', 'ISO-8859-15'], 
    ['Helvetica', 'ISO-8859-16'], 
    ['Times-Roman', 'CP1250'], 
    ['Times-Roman', 'CP1252'], 
    ['Times-Roman', 'CP1254'], 
    ['Courier', 'MacTurkish'], 
    ['Courier', 'Macintosh'], 
    # ['Times-Roman', 'WinAnsiEncoding'], 
    # ['Courier', 'WinAnsiEncoding'], 
    ['Symbol', 'StandardEncoding'], 
    ['ZapfDingbats', 'StandardEncoding']
  ]
  fonts.each do |name, encoding|
    w.page(:units => :in, :margins => 0.5) do |p|
      p.print "#{name} - #{encoding}", :underline => true
      p.font 'Courier', 10
      p.move_to 0, 0.5
      stops = (1..16).map { |stop| stop.quo(2.3) }
      p.tabs stops
      16.times do |offset|
        p.tab { 1 / 2.3 }
        p.print offset.to_s(16).upcase
      end
      p.font name, 16, :encoding => encoding
      32.upto(255) do |i|
        p.tab { 1 / 2.3 }
        p.print i.chr
      end
      p.vtabs stops.map { |stop| stop + 0.5 }
      p.move_to 0, 0
      p.font 'Courier', 10
      2.upto(15) do |offset|
        p.vtab
        p.print offset.to_s(16).upcase, :align => :left
      end
    end
  end
end

def bullets(w)
  w.page(:units => :in, :margins => 0.5) do |p|
    p.puts("Bullets", :underline => true)
    p.new_line
    p.font('Helvetica', 12)
    p.v_text_align :top

    lines = LOREM.split('.').map { |sentence| sentence << '.' }
    p.bullet(:star, :width => 0.25) do |w|
      prev_font = w.font('ZapfDingbats', 12)
      w.print(0x4E.chr)
      w.font(prev_font)
    end
    p.bullet('diamond', :width => 0.635, :units => :cm) do |w|
      prev_font = w.font('Symbol', 12)
      w.print(0xA8.chr)
      w.font(prev_font)
    end
    r = p.text_height.quo(3)
    p.bullet(:triangle, :width => 0.25) do |w|
      pos = w.pen_pos
      w.circle(pos.x + r, pos.y + r, r)
    end

    lines.each { |para| p.paragraph(para, :bullet => :star) }
    lines.each { |para| p.paragraph(para, :bullet => :diamond, :align => :justify) }
    lines.each { |para| p.paragraph(para, :bullet => :triangle) }
  end
end

def rich_text(w)
  w.page(:units => :in, :margins => 0.5) do |p|
    p.puts("Rich Text", :underline => true)
    p.new_line

    rt = EideticPDF::PdfText::RichText.new
    p.font('Helvetica', 12)
    rt.add("Here is some ", p.font)
    p.font('Helvetica', 12, :weight => 'Bold')
    rt.add("Bold", p.font)
    p.font('Helvetica', 12)
    rt.add(" text.", p.font)
    p.paragraph(rt)

    rt = EideticPDF::PdfText::RichText.new
    p.font('Helvetica', 12)
    rt.add("Here is some ", p.font)
    p.font('Helvetica', 12, :style => 'Italic')
    rt.add("Italic", p.font)
    p.font('Helvetica', 12)
    rt.add(" text.", p.font)
    p.paragraph(rt)

    rt = EideticPDF::PdfText::RichText.new
    p.font('Helvetica', 12)
    rt.add("Here is some ", p.font)
    p.font('Helvetica', 12, :style => 'BoldItalic')
    rt.add("Bold, Italic", p.font)
    p.font('Helvetica', 12)
    rt.add(" text.", p.font)
    p.paragraph(rt)

    rt = EideticPDF::PdfText::RichText.new
    p.font('Helvetica', 12)
    rt.add("Here is some ", p.font)
    rt.add("Red", p.font, :color => 'Red')
    rt.add(" text.", p.font)
    p.paragraph(rt)

    rt = EideticPDF::PdfText::RichText.new
    p.font('Helvetica', 12)
    rt.add("Here is some ", p.font)
    rt.add("Underlined", p.font, :underline => true)
    rt.add(" text.", p.font)
    p.paragraph(rt)

    rt = EideticPDF::PdfText::RichText.new
    p.font('Helvetica', 12)
    rt.add("This text is ", p.font)
    p.font('Helvetica', 12, :weight => 'Bold')
    rt.add("Bold.  ", p.font)

    p.font('Helvetica', 12)
    rt.add("This text is ", p.font)
    rt.add("Underlined", p.font, :underline => true)
    rt.add(".  ", p.font)

    rt.add("This text is ", p.font)
    rt.add("Red.  ", p.font, :color => 'Red')

    rt.add("This text is normal.", p.font)

    p.paragraph(rt)
  end
end

def angled_lines(w)
  w.page(:units => :in, :margins => 0.5) do |p|
    p.puts("Angled Lines", :underline => true)
    p.new_line
    x, y = 3.75, 5
    p.line_color 'Black'
    0.upto(14) do |step|
      p.line(x, y, step * 6, x)
    end
    p.line_color 'Red'
    15.upto(29) do |step|
      p.line(x, y, step * 6, x)
    end
    p.line_color 'Green'
    30.upto(44) do |step|
      p.line(x, y, step * 6, x)
    end
    p.line_color 'Blue'
    45.upto(59) do |step|
      p.line(x, y, step * 6, x)
    end
  end
end

def rotations(w)
  w.page(:units => :in, :margins => 0.5) do |p|
    p.puts("Rotate", :underline => true)
    p.line_dash_pattern :dashed
    p.move_to(0, 2); p.line_to(p.canvas_width, 2)
    p.move_to(p.canvas_width.quo(2), 0); p.line_to(p.canvas_width.quo(2), 4)
    p.line_dash_pattern :dotted
    0.step(90, 30) do |angle|
      p.rotate(angle, p.canvas_width.quo(2), 2) do
        p.rectangle(p.canvas_width.quo(2), 2, 2, 1)
        p.print_xy(p.canvas_width.quo(2) + 0.25, 2.25, "Hello")
      end
    end
    p.line_dash_pattern :dashed
    p.font("Helvetica", 12)
    x, y = p.canvas_width.quo(2), p.canvas_height - 2
    p.move_to(0, y); p.line_to(p.canvas_width, y)
    p.move_to(x, y - 2); p.line_to(x, y + 2)
    p.line_dash_pattern :dotted
    p.rotate(30, x, y) do
      p.rectangle(x - 2, y - 1.25, 4, 2.5)
      p.paragraph_xy(x - 2, y - 1.25, LOREM, :width => 4, :height => 2.5)
    end
  end
end

def scaling(w)
  w.page(:units => :in, :margins => 0.5) do |p|
    p.puts("Scale", :underline => true)
    1.upto(10) { |i| p.move_to(0, i); p.line_to(0.125, i) }
    p.line_dash_pattern :dotted
    [[0.5, 1, 1.0, 1.0],
     [0.5, 4, 0.75, 0.75],
     [0.5, 7, 0.5, 0.5]
    ].each do |parms|
      p.scale(*parms) do
        p.font("Helvetica", 12)
        p.rectangle(0, 0, 4.0, 2.5)
        p.paragraph_xy(0, 0, LOREM, :width => 4.0, :height => 2.5)
      end
    end
  end
end

def justification(w)
  width = 1.5
  w.page(:units => :in, :margins => 0.5) do |p|
    p.puts("Justification", :underline => true)
    p.paragraph(LOREM, :align => :justify, :width => 7.5)
    p.new_line
    p.paragraph(LOREM, :align => :justify, :width => 3)
    p.new_line
    p.paragraph(LOREM + " abcdefghijklmnopqrstuvwxyz", :align => :justify, :width => width)
    # p.move_to(width, 0); p.line_to(width, w.canvas_height)
  end
end

start = Time.now
docw = EideticPDF::DocumentWriter.new

# docw.doc(:font => { :name => 'Courier', :size => 10 }, :orientation => :landscape, :pages_up => [3, 2], :pages_up_layout => :down) do |w|
docw.doc(:font => { :name => 'Courier', :size => 10 }, :built_in_fonts => BuiltInFonts) do |w|
  justification(w)
  scaling(w)
  rotations(w)
  angled_lines(w)
  rich_text(w)
  bullets(w)
  print_text(w)
  type1_font_names(w) # 1.9
  truetype_font_names(w) if BuiltInFonts
  stars(w)
  polygons(w)
  pies(w)
  compound_paths(w)
  filled_shapes(w)
  circles_and_rectangles(w)
  ellipses(w)
  filled_rectangles(w)
  line_widths_and_patterns(w)
  print_angled_text_etc(w)
  arcs(w)
  pt_units(w)
  cm_grid(w)
  inch_grid(w)
  dp_grid(w)
  images(w) # 1.9
  clipping(w) # 1.9
  text_clipping(w) # 1.9
  text_encodings(w) unless BuiltInFonts # 1.9
  landscape_orientation(w)
end

File.open("test.pdf","w") { |f| f.write(docw) }

elapsed = Time.now - start
puts "Elapsed: #{(elapsed * 1000).round} ms"
`open test.pdf` if RUBY_PLATFORM =~ /darwin/ and ($0 !~ /rake_test_loader/ and $0 !~ /rcov/)
