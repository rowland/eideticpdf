#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-11-27.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

$: << File.dirname(__FILE__) + '/../'
require 'test/unit'
require 'epdft'
require 'epdfk'

include EideticPDF

Font = Struct.new(:name, :size, :style, :color, :encoding, :sub_type, :widths, :ascent, :descent, :height)

class TestTextWrapper < Test::Unit::TestCase
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
    assert_equal("Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut ", @wrapper.next(500).first.text)
    assert_equal("labore et dolore magna aliqua.\n", @wrapper.next(500).first.text)
    assert_equal("Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea ", @wrapper.next(500).first.text)
    assert_equal("commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum ", @wrapper.next(500).first.text)
    assert_equal("dolore eu fugiat nulla pariatur.\n", @wrapper.next(500).first.text)
    assert_equal("Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim ", @wrapper.next(500).first.text)
    assert_equal("id est laborum.", @wrapper.next(500).first.text)
    assert_equal(nil, @wrapper.next(500))
  end

  def test_max_height
    line = @wrapper.next(500)
    assert_in_delta(11.1, line.height, 0.1)
  end
end
