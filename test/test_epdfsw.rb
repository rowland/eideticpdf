#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-07-14.
#  Copyright (c) 2007, 2008 Eidetic Software. All rights reserved.
#
# Eidetic PDF Stream Writer Test Cases

$: << File.dirname(__FILE__) + '/../lib'
require 'test/unit'
require 'epdfsw'

include EideticPDF

class MiscWriterTestCases < Test::Unit::TestCase
  def setup
    @stream = ''
    @writer = MiscWriter.new(@stream)
  end

  def test_set_gray_fill
    @writer.set_gray_fill(0.4)
    assert_equal("0.4 g\n", @stream)
  end

  def test_set_gray_stroke
    @writer.set_gray_stroke(0.9)
    assert_equal("0.9 G\n", @stream)
  end

  def test_set_cmyk_color_fill
    @writer.set_cmyk_color_fill(0.5, 0.5, 0.5, 0.5)
    assert_equal("0.5 0.5 0.5 0.5 k\n", @stream)
  end

  def test_set_cmyk_color_stroke
    @writer.set_cmyk_color_stroke(0.5, 0.5, 0.5, 0.5)
    assert_equal("0.5 0.5 0.5 0.5 K\n", @stream)
  end

  def test_set_rgb_color_fill
    @writer.set_rgb_color_fill(0.3, 0.6, 0.9)
    assert_equal("0.3 0.6 0.9 rg\n", @stream)
  end

  def test_set_rgb_color_stroke
    @writer.set_rgb_color_stroke(0.3, 0.6, 0.9)
    assert_equal("0.3 0.6 0.9 RG\n", @stream)
  end

  def test_set_color_space_fill
    @writer.set_color_space_fill('DeviceGray')
    assert_equal("/DeviceGray cs\n", @stream)
  end

  def test_set_color_space_stroke
    @writer.set_color_space_stroke('DeviceGray')
    assert_equal("/DeviceGray CS\n", @stream)
  end

  def test_set_color_fill
    @writer.set_color_fill([0.1, 0.2, 0.3, 0.4])
    assert_equal("0.1 0.2 0.3 0.4 sc\n", @stream)
  end

  def test_set_color_stroke
    @writer.set_color_stroke([0.1, 0.2, 0.3, 0.4])
    assert_equal("0.1 0.2 0.3 0.4 SC\n", @stream)
  end

  # xxx scn, SCN: patterns and separations
  def test_set_color_rendering_intent
    @writer.set_color_rendering_intent("RelativeColorimetric")
    assert_equal("/RelativeColorimetric ri\n", @stream)
  end

  def test_x_object
    @writer.x_object('Image1')
    assert_equal("/Image1 Do\n", @stream)
  end
end

class GraphWriterTestCases < Test::Unit::TestCase
  def setup
    @stream = ''
    @writer = GraphWriter.new(@stream)
  end

  def test_save_graphics_state
    @writer.save_graphics_state
    assert_equal("q\n", @stream)
  end

  def test_restore_graphics_state
    @writer.restore_graphics_state
    assert_equal("Q\n", @stream)
  end

  def test_concat_matrix
    @writer.concat_matrix(1.1, 2.2, 3.3, 4.4, 5.5, 6.6)
    assert_equal("1.1 2.2 3.3 4.4 5.5 6.6 cm\n", @stream)
  end

  def test_set_flatness
    @writer.set_flatness(50)
    assert_equal("50 i\n", @stream)
  end

  def test_set_line_cap_style
    @writer.set_line_cap_style(0)
    assert_equal("0 J\n", @stream)
  end

  def test_set_line_dash_pattern
    @writer.set_line_dash_pattern('[2 3] 11')
    assert_equal("[2 3] 11 d\n", @stream)
  end

  def test_set_line_join_style
    @writer.set_line_join_style(0)
    assert_equal("0 j\n", @stream)
  end

  def test_set_line_width
    @writer.set_line_width(3)
    assert_equal("3 w\n", @stream)
  end

  def test_set_miter_limit
    @writer.set_miter_limit(3.6)
    assert_equal("3.6 M\n", @stream)
  end

  def test_move_to
    @writer.move_to(4, 5.55)
    assert_equal("4 5.55 m\n", @stream)
  end

  def test_line_to
    @writer.line_to(5.55, 4)
    assert_equal("5.55 4 l\n", @stream)
  end

  def test_curve_to
    @writer.curve_to(1.1, 2.2, 3.3, 4.4, 5.5, 6.6)
    assert_equal("1.1 2.2 3.3 4.4 5.5 6.6 c\n", @stream)
  end

  def test_rectangle
    @writer.rectangle(5.5, 5.5, 4, 6)
    assert_equal("5.5 5.5 4 6 re\n", @stream)
  end

  def test_close_path
    @writer.close_path
    assert_equal("h\n", @stream)
  end

  def test_new_path
    @writer.new_path
    assert_equal("n\n", @stream)
  end

  def test_stroke
    @writer.stroke
    assert_equal("S\n", @stream)
  end

  def test_close_path_and_stroke
    @writer.close_path_and_stroke
    assert_equal("s\n", @stream)
  end

  def test_fill
    @writer.fill
    assert_equal("f\n", @stream)
  end

  def test_eo_fill
    @writer.eo_fill
    assert_equal("f*\n", @stream)
  end

  def test_fill_and_stroke
    @writer.fill_and_stroke
    assert_equal("B\n", @stream)
  end

  def test_close_path_fill_and_stroke
    @writer.close_path_fill_and_stroke
    assert_equal("b\n", @stream)
  end

  def test_eo_fill_and_stroke
    @writer.eo_fill_and_stroke
    assert_equal("B*\n", @stream)
  end

  def test_close_path_eo_fill_and_stroke
    @writer.close_path_eo_fill_and_stroke
    assert_equal("b*\n", @stream)
  end

  def test_clip
    @writer.clip
    assert_equal("W\n", @stream)
  end

  def test_eo_clip
    @writer.eo_clip
    assert_equal("W*\n", @stream)
  end

  def test_make_line_dash_pattern
    assert_equal("[1 2 3] 2", @writer.make_line_dash_pattern([1, 2, 3], 2))
  end
end

class TextWriterTestCases < Test::Unit::TestCase
  def setup
    @stream = ''
    @writer = TextWriter.new(@stream)
  end
  
  def test_open
    @writer.open
    assert_equal("BT\n", @stream)
  end
  
  def test_close
    @writer.close
    assert_equal("ET\n", @stream)
  end

  def test_set_char_spacing
    @writer.set_char_spacing(5)
    assert_equal("5 Tc\n", @stream)
  end

  def test_set_word_spacing
    @writer.set_word_spacing(5)
    assert_equal("5 Tw\n", @stream)
  end

  def test_set_horiz_scaling
    @writer.set_horiz_scaling(90)
    assert_equal("90 Tz\n", @stream)
  end

  def test_set_leading
    @writer.set_leading(8)
    assert_equal("8 TL\n", @stream)
  end

  def test_set_font_and_size
    @writer.set_font_and_size("Arial", 12)
    assert_equal("/Arial 12 Tf\n", @stream)
  end

  def test_set_rendering_mode
    @writer.set_rendering_mode(0)
    assert_equal("0 Tr\n", @stream)
  end

  def test_set_rise
    @writer.set_rise(0)
    assert_equal("0 Ts\n", @stream)
  end

  def test_move_by
    @writer.move_by(7, 11.5)
    assert_equal("7 11.5 Td\n", @stream)
  end

  def test_move_by_and_set_leading
    @writer.move_by_and_set_leading(5.5, 12)
    assert_equal("5.5 12 TD\n", @stream)
  end

  def test_set_matrix
    @writer.set_matrix(1.1, 2, 3.3, 4, 5.5, 6)
    assert_equal("1.1 2 3.3 4 5.5 6 Tm\n", @stream)
  end

  def test_next_line
    @writer.next_line
    assert_equal("T*\n", @stream)
  end

  def test_show
    @writer.show("Hello")
    assert_equal("(Hello) Tj\n", @stream)
  end

  def test_next_line_show
    @writer.next_line_show("Goodbye")
    assert_equal("(Goodbye) '", @stream)
  end

  def test_set_spacing_next_line_show
    @writer.set_spacing_next_line_show(5, 11.5, "Hello and goodbye")
    assert_equal("5 11.5 (Hello and goodbye) \"\n", @stream)
  end

  def test_show_with_dispacements
    a = PdfObjects::PdfArray.new([
      PdfObjects::PdfString.new('H'), 
      PdfObjects::PdfInteger.new(120), 
      PdfObjects::PdfString.new('e'), 
      PdfObjects::PdfInteger.new(80), 
      PdfObjects::PdfString.new('y')])
    @writer.show_with_dispacements(a)
    assert_equal("[(H) 120 (e) 80 (y) ] TJ\n", @stream)
  end
end
