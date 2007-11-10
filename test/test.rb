#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-09-30.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

$: << File.dirname(__FILE__) + '/../'
require 'pdfw'
include PdfW

def grid(w, width, height, xoff, yoff, step=1)
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
  PdfW::UNIT_CONVERSION[:dp] = 0.072
  w.start_page(:units => :dp)
  w.set_font("Helvetica", 10)
  w.print_xy(250, 250, "Dave Points Squares")
  grid(w, width, height, xoff, yoff, 1000)
  w.end_page
end

def circles_and_rectangles(w)
  w.start_page(:units => :in)
  w.rectangle(1, 1, 6.5, 9)
  w.rectangle(2, 2, 4.5, 7)
  w.circle(4.25, 5.5, 3.25)
  w.end_page
end

def font_names(w)
  w.page(:units => :cm) do |p|
    p.move_to(1, 1)
    PdfK::FONT_NAMES.each do |font_name|
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
  w.move_to(1, 3); w.line_to(9,3)
  w.v_text_align = :bottom
  w.move_to(1, 3); w.print("Text above the line.")
  w.v_text_align = :top
  w.move_to(5, 3); w.print("Text below the line.")
  
  # test angled text display
  
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

docw = PdfDocumentWriter.new
docw.doc do |w|
  print_angled_text(w)
  print_text(w)
  circles_and_rectangles(w)
  cm_grid(w)
  inch_grid(w)
  dp_grid(w)
  font_names(w)
end

File.open("test.pdf","w") { |f| f.write(docw) }
`open test.pdf`
#print docw
