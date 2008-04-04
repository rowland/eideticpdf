#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-12-09.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

$: << File.dirname(__FILE__) + '/../'
require 'epdfdw'

start = Time.now
docw = EideticPDF::DocumentWriter.new

class Table
  def initialize(w, left_edge, item_edge)
    @w = w
    @left_edge = left_edge
    @item_edge = item_edge
  end
  def row(label, lorem, top)
    @w.font("Helvetica", 12)
    @w.move_to(@left_edge, top)
    @w.line_height 1.22
    @w.font("Helvetica-Bold", 12)
    @w.paragraph(label, {:width => 1.5})

    @w.font("Helvetica", 12)
    @w.move_to(@item_edge, top)
    @w.paragraph(lorem, {:width => 8})

    @w.line_color "DarkGray"
    line_ypos = @w.pen_pos[1]
    @w.move_to(@left_edge, line_ypos)
    @w.line_to(10.7, line_ypos) 
    @w.line_color "Black"
  end
end

docw.doc(
  :font => { :name => 'Times-Roman', :size => 12 },
  :orientation => :landscape,
  :pages_up => [2, 1],
  :unscaled => true,
  :units => :in,
  :margins => 0.0) do |w|
  #side bar
  (1..1).to_a.each do |i|
    w.page do |p|
      p.fill_color 'DarkGray';
      p.rectangle(0, 0, 0.5, 8.5, :border => false, :fill => true)
      p.line_color 0x666666
      p.move_to 0.5, 0
      p.line_to 0.5, 8.5
      p.font("Helvetica", 18)
      p.font_color "White"
      p.print_xy(0.2, 2.5, "Use Case : UC-00#{i}", {:angle => 90})
      #header
      p.line_color 'DarkGray'
      p.move_to 0.7, 1
      p.line_to 10.7, 1
      p.move_to 0.7, 0.73
      p.font("Helvetica", 18)
      p.font_color 0x447700
      title = "Product Activation"
      p.print(title)
      #table
      p.line_width 0.005
      p.line_color "Black"
      p.font_color "Black"
      p.line_height 1.22

      left_edge = 0.7
      item_edge = 2.3 
      lorem = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

      table = Table.new(p, left_edge, item_edge)
      table.row("Summary:", lorem, 1.1)
      ypos = p.pen_pos[1] + 0.1
      table.row("Freqyency:", "Always", ypos)
      ypos = p.pen_pos[1] + 0.1
      table.row("Primary Actors:", "Me", ypos)
      ypos = p.pen_pos[1] + 0.1
      table.row("Stakeholders:", "Me", ypos)
      ypos = p.pen_pos[1] + 0.1
      table.row("Precondistions:", lorem, ypos)
      ypos = p.pen_pos[1] + 0.1
      table.row("Main Success Scenario:", lorem, ypos)
      ypos = p.pen_pos[1] + 0.1
      table.row("Alternative Scenarios:", lorem, ypos)
      ypos = p.pen_pos[1] + 0.1
      table.row("Notes and Questions:", lorem, ypos)
    end
  end
  w.page do |p|
    i = 2
    p.fill_color 'DarkGray';
    p.rectangle(0, 0, 0.5, 8.5, :border => false, :fill => true)
    p.line_color 0x666666
    p.move_to 0.5, 0
    p.line_to 0.5, 8.5
    p.font("Helvetica", 18)
    p.font_color "White"
    p.print_xy(0.2, 2.5, "Use Case : UC-00#{i}", {:angle => 90})
  end
end

File.open("use_cases.pdf","w") { |f| f.write(docw) }
#`open use_cases.pdf`
