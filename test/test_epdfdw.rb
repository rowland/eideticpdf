#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-07-14.
#  Copyright (c) 2007, 2008 Eidetic Software. All rights reserved.
#
# Eidetic PDF Document Writer Tests

$: << File.dirname(__FILE__) + '/../lib'
require 'test/unit'
require File.join(File.dirname(__FILE__), 'test_helpers')
require 'epdfdw'

include EideticPDF

class DocumentWriterTestCases < Test::Unit::TestCase
  SAYING = "This is the first day of the *rest* of your life--or so it has been said (by a forgotten pundit)."
  SAYING_WRAPPED = ["This is the first day ", "of the *rest* of your ", "life--or so it has been", "said (by a forgotten ", "pundit)."]
  S2 = "\tThis paragraph starts with a tab\n\nand has two embedded newlines."
  S2_WRAPPED = ["\tThis paragraph starts with a tab", '', "and has two embedded newlines."]

  def setup
    PageWriter::DEFAULT_FONT.update(:name => 'Courier', :size => 10)
    @doc = DocumentWriter.new
    @doc.open
    @doc.open_page(:units => :cm)
  end

  def teardown
    @doc.close_page
    @doc.close
  end

  def test_text_ascent
    assert_equal(6.29, @doc.text_ascent(:pt))
  end

  def test_text_height
    assert_equal(1.7, @doc.line_height)
    assert_equal(7.86, @doc.text_height(:pt))
  end

  def test_height
    h1 = @doc.height("Hello", :pt)
    assert_in_delta(13.3, h1, 0.1)
    h2 = @doc.height(SAYING_WRAPPED, :pt)
    assert_in_delta(66.8, h2, 0.1)
  end

  def test_wrap
    lines = @doc.wrap(SAYING, 5)
    assert_equal(SAYING_WRAPPED, lines)
  end

  def test_wrap2
    lines = @doc.wrap(S2, 10)
    assert_equal(S2_WRAPPED, lines)
  end

  def test_pen_pos
    # default position
    assert_equal(0, @doc.pen_pos.x)
    assert_equal(0, @doc.pen_pos.y)
    
    # after moving to integer position
    @doc.move_to(5, 6)
    assert_equal(5, @doc.pen_pos.x)
    assert_equal(6, @doc.pen_pos.y)

    # after moving to float position
    @doc.move_to(10.5, 11.6)
    assert_in_delta(10.5, @doc.pen_pos.x, 0.1)
    assert_in_delta(11.6, @doc.pen_pos.y, 0.1)

    # also works like move_to
    @doc.pen_pos(10, 20)
    assert_equal(10, @doc.pen_pos.x)
    assert_equal(20, @doc.pen_pos.y)
  end
  
  def test_move_by
    @doc.move_to(5, 6)
    @doc.move_by(5, 4)
    assert_close([10, 10], @doc.pen_pos.to_a)
    @doc.move_by(-3, 0)
    assert_close([7, 10], @doc.pen_pos.to_a)
    @doc.move_by(0, -7)
    assert_close([7, 3], @doc.pen_pos.to_a)
  end

  def test_margins
    assert_equal([0, 0, 0, 0], @doc.margins)
    assert_equal(0, @doc.margin_top)
    assert_equal(0, @doc.margin_right)
    assert_equal(0, @doc.margin_bottom)
    assert_equal(0, @doc.margin_left)
    @doc.margins(1)
    assert_equal([1, 1, 1, 1], @doc.margins)
    @doc.margins(1, 2)
    assert_equal([1, 2, 1, 2], @doc.margins)
    @doc.margins(1, 2, 3, 4)
    assert_array_in_delta([1, 2, 3, 4], @doc.margins, 2 ** -20)
    assert_in_delta(1.0, @doc.margin_top, 0.01)
    assert_in_delta(2.0, @doc.margin_right, 0.01)
    assert_in_delta(3.0, @doc.margin_bottom, 0.01)
    assert_in_delta(4.0, @doc.margin_left, 0.01)
    @doc.margins(5, 6, 7)
    assert_array_in_delta([1, 2, 3, 4], @doc.margins, 2 ** -20) # unchanged
    @doc.margins(5, 6, 7, 8, 9)
    assert_array_in_delta([1, 2, 3, 4], @doc.margins, 2 ** -20) # still unchanged
    assert_equal("q\n1 0 0 1 28.35 -28.35 cm\nQ\nq\n1 0 0 1 56.7 -28.35 cm\nQ\nq\n1 0 0 1 113.4 -28.35 cm\n", @doc.pages.first.stream)
  end

  def test_font
    # default font
    assert_equal('Courier', @doc.font.name)
    assert_equal(10, @doc.font.size)
    # changed
    @doc.font 'Times', 12, :style => 'Italic'
    assert_equal('Times', @doc.font.name)
    assert_equal(12, @doc.font.size)
    assert_equal('Italic', @doc.font.style)

    # prev_font = @doc.font
    prev_font = @doc.font 'Helvetica', 14, :color => 'Blue'
    assert_equal('Blue', @doc.font_color)
    # check previous font
    assert_equal('Times', prev_font.name)
    assert_equal(12, prev_font.size)
    assert_equal('Italic', prev_font.style)
    # set font back to previous font
    @doc.font prev_font
    # check that settings took
    assert_equal('Times', @doc.font.name)
    assert_equal(12, @doc.font.size)
    assert_equal('Italic', @doc.font.style)
  end

  def test_font_style
    # default style
    assert_equal('', @doc.font_style)
    # changed
    prev_font_style = @doc.font_style 'Bold'
    assert_equal('', prev_font_style)
    assert_equal('Bold', @doc.font_style)
    # AFM font metrics backend ignores bogus styles.
    # invalid style
    # assert_raise(Exception) { @doc.font_style 'Bogus' }
    # unchanged by invalid style
    # assert_equal('Bold', @doc.font_style)
  end

  def test_font_size
    # default size
    assert_equal(10, @doc.font_size)
    # changed
    prev_font_size = @doc.font_size 12
    assert_equal(10, prev_font_size)
    assert_equal(12, @doc.font_size)
    # changed to float
    @doc.font_size 14.5
    assert_equal(14.5, @doc.font_size)
  end

  def test_font_color
    # default color
    assert_equal(0, @doc.font_color)
    # changed
    prev_font_color = @doc.font_color 'Blue'
    assert_equal(0, prev_font_color)
    assert_equal('Blue', @doc.font_color)
    # rgb
    @doc.font_color [0xFF,0,0]
    assert_equal(0xFF0000, @doc.font_color)
  end

  def test_fill_color
    # default color
    assert_equal(0xFFFFFF, @doc.fill_color)
    # changed
    prev_fill_color = @doc.fill_color 'Blue'
    assert_equal(0xFFFFFF, prev_fill_color)
    assert_equal('Blue', @doc.fill_color)
    # rgb
    @doc.fill_color [0xFF,0,0]
    assert_equal(0xFF0000, @doc.fill_color)
  end

  def test_line_color
    # default color
    assert_equal(0, @doc.line_color)
    # changed
    prev_line_color = @doc.line_color 'Blue'
    assert_equal(0, prev_line_color)
    assert_equal('Blue', @doc.line_color)
    # rgb
    @doc.line_color [0xFF,0,0]
    assert_equal(0xFF0000, @doc.line_color)
  end

  def test_line_width
    # default width
    assert_equal(1.0, @doc.line_width(:pt))
    # changed
    prev_line_width = @doc.line_width 1
    assert_equal(1/UNIT_CONVERSION[:cm], prev_line_width)
    assert_equal(1, @doc.line_width)
    # alternate units
    assert_equal(28.35, @doc.line_width(:pt))
    @doc.line_width 1, :in
    assert_equal(72, @doc.line_width(:pt))
    @doc.line_width "2in"
    assert_in_delta(5.08, @doc.line_width, 0.01)
  end

  def test_units
    [:pt, :cm, :in].each do |units|
      @doc.units(units)
      assert_equal(units, @doc.units)
    end
  end

  def test_tabs
    assert_nil @doc.tabs
    @doc.tabs [1, 2, 3]
    assert_equal [1, 2, 3], @doc.tabs
    @doc.tabs []
    assert_nil @doc.tabs
    @doc.tabs '4, 5, 6'
    assert_equal [4, 5, 6], @doc.tabs
    @doc.tabs false
    assert_nil @doc.tabs
  end

  def test_tab
    @doc.tabs [1.5, 3, 4.5, 6]
    assert_close([0, 0], @doc.pen_pos.to_a)
    @doc.tab
    assert_close([1.5, 0], @doc.pen_pos.to_a)
    @doc.tab
    assert_close([3, 0], @doc.pen_pos.to_a)
    @doc.tab
    assert_close([4.5, 0], @doc.pen_pos.to_a)
    @doc.tab
    assert_close([6, 0], @doc.pen_pos.to_a)
    @doc.tab
    assert_close([1.5, @doc.height], @doc.pen_pos.to_a)
  end

  def test_vtabs
    assert_nil @doc.vtabs
    @doc.vtabs [1, 2, 3]
    assert_equal [1, 2, 3], @doc.vtabs
    @doc.vtabs []
    assert_nil @doc.vtabs
    @doc.vtabs '4, 5, 6'
    assert_equal [4, 5, 6], @doc.vtabs
    @doc.vtabs false
    assert_nil @doc.vtabs
  end

  def test_vtab
    @doc.vtabs [1.5, 3, 4.5, 6]
    assert_close([0, 0], @doc.pen_pos.to_a)
    @doc.vtab
    assert_close([0, 1.5], @doc.pen_pos.to_a)
    @doc.vtab
    assert_close([0, 3], @doc.pen_pos.to_a)
    @doc.vtab
    assert_close([0, 4.5], @doc.pen_pos.to_a)
    @doc.vtab
    assert_close([0, 6], @doc.pen_pos.to_a)
    @doc.vtab { 2.5 }
    assert_close([2.5, 1.5], @doc.pen_pos.to_a)
  end

  def test_indent
    assert_close([0, 0], @doc.pen_pos.to_a) # starting location
    @doc.indent 2
    assert_equal(2, @doc.pen_pos.x, "indent should set pen_pos.x")
    prev_indent = @doc.indent 2
    assert_equal(4, @doc.pen_pos.x, "normal indents are additive")
    assert_equal(2, prev_indent)
    prev_indent = @doc.indent -1
    assert_equal(3, @doc.pen_pos.x, "the other side of additive")
    assert_equal(4, prev_indent)
    @doc.indent 5, true
    assert_equal(5, @doc.pen_pos.x, "absolute indent")
    @doc.print "here we are: "
    @doc.puts "testing indent"
    assert_equal(5, @doc.pen_pos.x, "normal puts should return pen_pos.x to indent")
    assert_close(@doc.height, @doc.pen_pos.y)
  end

  def test_paragraph
    assert_nothing_raised(Exception) do
      @doc.paragraph("Hello, World!")
    end
  end

  def test_bullet
    @doc.bullet(:star, :width => 1) do |w|
      prev_font = w.font('ZapfDingbats', 12)
      w.print(0x4E.chr)
      w.font(prev_font)
    end

    star = @doc.bullets[:star]
    assert_not_nil(star)
    assert_equal('star', star.name)
    assert_equal(UNIT_CONVERSION[:cm], star.width)

    @doc.bullet('diamond') do |w|
      prev_font = w.font('Symbol', 12)
      w.print(0xA8.chr)
      w.font(prev_font)
    end

    diamond = @doc.bullet(:diamond)
    assert_not_nil(diamond)
    assert_equal('diamond', diamond.name)
    assert_equal(36, diamond.width)

    @doc.bullet(:dagger, :width => 1, :units => :in) do |w|
      w.print(0x86.chr)
    end

    dagger = @doc.bullet(:dagger)
    assert_not_nil(dagger)
    assert_equal('dagger', dagger.name)
    assert_equal(72, dagger.width)
  end

  def test_underline
    assert(!@doc.underline)
    @doc.underline(true)
    assert(@doc.underline)
    @doc.underline(false)
    assert(!@doc.underline)
  end

  def test_sub_page
    @doc.instance_eval do
      @pages_across, @pages_down = 2, 2
      @pages_up = @pages_across * @pages_down
      @options[:pages_up_layout] = :across
    end
    assert_equal [0, 2, 0, 2], @doc.send(:sub_page, 0) # top left
    assert_equal [1, 2, 0, 2], @doc.send(:sub_page, 1) # top right
    assert_equal [0, 2, 1, 2], @doc.send(:sub_page, 2) # bottom left
    assert_equal [1, 2, 1, 2], @doc.send(:sub_page, 3) # bottom right
    assert_equal [0, 2, 0, 2], @doc.send(:sub_page, 4) # top left
    assert_equal [1, 2, 0, 2], @doc.send(:sub_page, 5) # top right
    assert_equal [0, 2, 1, 2], @doc.send(:sub_page, 6) # bottom left
    assert_equal [1, 2, 1, 2], @doc.send(:sub_page, 7) # bottom right

    @doc.instance_eval do
      @options[:pages_up_layout] = :down
    end
    assert_equal [0, 2, 0, 2], @doc.send(:sub_page, 0) # top left
    assert_equal [0, 2, 1, 2], @doc.send(:sub_page, 1) # bottom left
    assert_equal [1, 2, 0, 2], @doc.send(:sub_page, 2) # top right
    assert_equal [1, 2, 1, 2], @doc.send(:sub_page, 3) # buttom right

    assert_equal [0, 2, 0, 2], @doc.send(:sub_page, 4) # top left
    assert_equal [0, 2, 1, 2], @doc.send(:sub_page, 5) # bottom left
    assert_equal [1, 2, 0, 2], @doc.send(:sub_page, 6) # top right
    assert_equal [1, 2, 1, 2], @doc.send(:sub_page, 7) # buttom right
  end
end
