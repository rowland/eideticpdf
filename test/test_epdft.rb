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
    @wrapper = PdfText::RichText.new(lorem, font, 12)
  end

  def test_initialize
    assert_not_nil(@wrapper)
    assert_not_nil(@wrapper.words)
    assert_equal(137, @wrapper.words.size)
    assert_equal("Lorem", @wrapper.words.first.text)
  end

  def test_next
    assert_equal("Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do ", @wrapper.next(500).first.text)
    assert_equal("eiusmod tempor incididunt ut labore et dolore magna aliqua.\n", @wrapper.next(500).first.text)
    assert_equal("Ut enim ad minim veniam, quis nostrud exercitation ullamco ", @wrapper.next(500).first.text)
    assert_equal("laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure ", @wrapper.next(500).first.text)
    assert_equal("dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat", @wrapper.next(500).first.text)
    assert_equal("nulla pariatur.\n", @wrapper.next(500).first.text)
    assert_equal("Excepteur sint occaecat cupidatat non proident, sunt in culpa qui ", @wrapper.next(500).first.text)
    assert_equal("officia deserunt mollit anim id est laborum.", @wrapper.next(500).first.text)
    assert_equal(nil, @wrapper.next(500))
  end
end