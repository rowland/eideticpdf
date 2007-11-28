#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-11-27.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

$: << File.dirname(__FILE__) + '/../'
require 'test/unit'
require 'epdft'
require 'epdfk'

include EideticPDF

class TestTextWrapper < Test::Unit::TestCase
  def setup
    lorem = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\n" <<
            "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute " <<
            "irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.\n" <<
            "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    font = PdfK::font_metrics('Helvetica')
    @wrapper = PdfText::TextWrapper.new(lorem, font, 12)
  end

  def test_initialize
    assert_not_nil(@wrapper)
    assert_not_nil(@wrapper.words)
    assert_equal(137, @wrapper.words.size)
    assert_equal("Lorem", @wrapper.words.first.text)
  end

  def test_next
    assert_equal("Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod", @wrapper.next(500).first.text)
    assert_equal("tempor incididunt ut labore et dolore magna aliqua.", @wrapper.next(500).first.text)
    assert_equal("Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris", @wrapper.next(500).first.text)
    assert_equal("nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit", @wrapper.next(500).first.text)
    assert_equal("in voluptate velit esse cillum dolore eu fugiat nulla pariatur.", @wrapper.next(500).first.text)
    assert_equal("Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia", @wrapper.next(500).first.text)
    assert_equal("deserunt mollit anim id est laborum.", @wrapper.next(500).first.text)
    assert_equal(nil, @wrapper.next(500))
  end
end