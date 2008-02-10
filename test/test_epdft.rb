#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-11-27.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

$: << File.dirname(__FILE__) + '/../'
require 'test/unit'
require File.join(File.dirname(__FILE__), 'test_helpers')
require 'epdft'
require 'epdfk'

include EideticPDF

Font = Struct.new(:name, :size, :style, :color, :encoding, :sub_type, :widths, :ascent, :descent, :height)

class RichTextTestCases < Test::Unit::TestCase
  def setup
    lorem = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\n" <<
            "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute " <<
            "irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.\n" <<
            "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    fm = PdfK::font_metrics('Helvetica')
    font = Font.new('Helvetica', 12, '', nil, 'WinAnsiEncoding', 'Type1', fm.widths, fm.ascent, fm.descent, fm.ascent + fm.descent.abs)
    @wrapper = PdfText::RichText.new(lorem, font)
  end

  def test_initialize
    assert_not_nil(@wrapper)
    assert_not_nil(@wrapper.words)
    assert_equal(137, @wrapper.words.size)
    assert_equal("Lorem", @wrapper.words.first.text)
  end

  def test_next
    assert_equal("Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut", @wrapper.next(500).first.text)
    assert_equal("labore et dolore magna aliqua.\n", @wrapper.next(500).first.text)
    assert_equal("Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea", @wrapper.next(500).first.text)
    assert_equal("commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum", @wrapper.next(500).first.text)
    assert_equal("dolore eu fugiat nulla pariatur.\n", @wrapper.next(500).first.text)
    assert_equal("Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim", @wrapper.next(500).first.text)
    assert_equal("id est laborum.", @wrapper.next(500).first.text)
    assert_equal(nil, @wrapper.next(500))
  end

  def test_max_height
    line = @wrapper.next(500)
    assert_in_delta(11.1, line.height, 0.1)
  end

  def count_lines(rich_text)
    result = 0
    result += 1 while rich_text.next(500)
    result
  end

  def test_clone
    word_count = @wrapper.words.size
    assert_equal(137, word_count)
    first_text = @wrapper.words.first.text
    wrapper_clone = @wrapper.clone
    assert(!first_text.equal?(wrapper_clone.words.first.text), "text not cloned")
    line_count = count_lines(wrapper_clone)
    assert_equal(7, line_count)
    assert_equal(0, wrapper_clone.words.size)
    assert_equal(word_count, @wrapper.words.size)
    assert_equal(line_count, count_lines(@wrapper))
  end

  def test_lines
    lines = @wrapper.lines(500)
    assert_equal(7, lines.size)
  end

  def test_height
    assert_close(11.1, @wrapper.height)
    assert_close(77.7, @wrapper.height(500))
  end

  def test_width
    assert_close(490.86, @wrapper.width(500))
  end
end

class RichTextTestCases2 < Test::Unit::TestCase
  def setup
    lorem = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\n" <<
            "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute " <<
            "irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.\n" <<
            "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    fm = PdfK::font_metrics('Helvetica')
    fm_b = PdfK::font_metrics('Helvetica-Bold')
    fm_i = PdfK::font_metrics('Helvetica-Oblique')
    fm_bi = PdfK::font_metrics('Helvetica-BoldOblique')
    @helv = Font.new('Helvetica', 12, '', nil, 'WinAnsiEncoding', 'Type1', fm.widths, fm.ascent, fm.descent, fm.ascent + fm.descent.abs)
    @helv_b = Font.new('Helvetica-Bold', 12, '', nil, 'WinAnsiEncoding', 'Type1', fm_b.widths, fm_b.ascent, fm_b.descent, fm_b.ascent + fm_b.descent.abs)
    @helv_i = Font.new('Helvetica-Italic', 12, '', nil, 'WinAnsiEncoding', 'Type1', fm_i.widths, fm_i.ascent, fm_i.descent, fm_i.ascent + fm_i.descent.abs)
    @helv_bi = Font.new('Helvetica-BoldItalic', 12, '', nil, 'WinAnsiEncoding', 'Type1', fm_bi.widths, fm_bi.ascent, fm_bi.descent, fm_bi.ascent + fm_bi.descent.abs)
  end

  def test_bold
    rt = PdfText::RichText.new
    rt.add("Here is some ", @helv)
    rt.add("Bold", @helv_b)
    rt.add(" text.", @helv)
    assert_in_delta(126, rt.width(500), 1)
    assert_in_delta(11.1, rt.height, 0.1)
    pieces = rt.next(500)
    assert_equal(3, pieces.size)
    assert_equal(@helv, pieces[0].font)
    assert_equal(@helv_b, pieces[1].font)
    assert_equal(@helv, pieces[2].font)
  end

  def test_italic
    rt = PdfText::RichText.new
    rt.add("Here is some ", @helv)
    rt.add("Italic", @helv_i)
    rt.add(" text.", @helv)
    assert_in_delta(124, rt.width(500), 1)
    assert_in_delta(11.1, rt.height, 0.1)
    pieces = rt.next(500)
    assert_equal(3, pieces.size)
    assert_equal(@helv, pieces[0].font)
    assert_equal(@helv_i, pieces[1].font)
    assert_equal(@helv, pieces[2].font)
  end

  def test_bold_italic
    rt = PdfText::RichText.new
    rt.add("Here is some ", @helv)
    rt.add("Bold, Italic", @helv_bi)
    rt.add(" text.", @helv)
    assert_in_delta(160, rt.width(500), 1)
    assert_in_delta(11.1, rt.height, 0.1)
    pieces = rt.next(500)
    assert_equal(3, pieces.size)
    assert_equal(@helv, pieces[0].font)
    assert_equal(@helv_bi, pieces[1].font)
    assert_equal(@helv, pieces[2].font)
  end

  def test_color
    rt = PdfText::RichText.new
    rt.add("Here is some ", @helv)
    rt.add("Red", @helv, :color => 'Red')
    rt.add(" text.", @helv)
    assert_in_delta(122, rt.width(500), 1)
    assert_in_delta(11.1, rt.height, 0.1)
    pieces = rt.next(500)
    assert_equal(3, pieces.size)
    assert_equal(@helv, pieces[0].font)
    assert_equal('Red', pieces[1].color)
    assert_equal(@helv, pieces[2].font)
  end

  def test_underline
    rt = PdfText::RichText.new
    rt.add("Here is some ", @helv)
    rt.add("Underlined", @helv, :underline => true)
    rt.add(" text.", @helv)
    assert_in_delta(158, rt.width(500), 1)
    assert_in_delta(11.1, rt.height, 0.1)
    pieces = rt.next(500)
    assert_equal(3, pieces.size)
    assert_equal(@helv, pieces[0].font)
    assert(pieces[1].underline)
    assert_equal(@helv, pieces[2].font)
  end
end
