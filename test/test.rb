#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-09-30.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

$: << File.dirname(__FILE__) + '/../'
require 'pdfw'
include PdfW

def inch_lines(w)
  w.start_page(:units => :in)
  w.set_font("Courier", 10)
  w.print_xy(0.25, 0.25, "Inch Squares")
  # vertical lines
  0.upto(8) do |x|
    puts "w.move_to(#{x + 0.25}, #{0.5})"
    w.move_to(x + 0.25, 0.5)
    puts "w.line_to(#{x + 0.25}, #{10.5})"
    w.line_to(x + 0.25, 10.5)
  end
  # horizontal lines
  0.upto(10) do |y|
    "w.move_to(#{0.25}, #{y + 0.5})"
    w.move_to(0.25, y + 0.5)
    "w.line_to(#{8.25}, #{y + 0.5})"
    w.line_to(8.25, y + 0.5)
  end
  w.end_page
end

docw = PdfDocumentWriter.new
docw.begin_doc
inch_lines(docw)
docw.start_page(:units => :in)
# test move_to and line_to
docw.move_to(1, 1)
docw.line_to(7.5, 1)
docw.line_to(7.5, 10)
docw.line_to(1, 10)
docw.line_to(1, 1)
# test rectangle
docw.rectangle(2, 2, 4.5, 7)
# test circle
docw.circle(4.25, 5.5, 3.25)
docw.new_page(:units => :cm)
docw.move_to(1, 1)
docw.set_font("Helvetica", 12)
docw.print("Hello, World!")
docw.new_page(:units => :cm)
docw.move_to(1, 1)
PdfK::FONT_NAMES.each do |font_name|
  docw.set_font(font_name, 12)
  docw.puts(font_name)
end
docw.end_page
docw.end_doc

File.open("test.pdf","w") { |f| f.write(docw) }
`open test.pdf`
#print docw
