#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-07-14.
#  Copyright (c) 2007, 2008 Eidetic Software. All rights reserved.
#
# Eidetic PDF PageWriter Test Cases

$: << File.dirname(__FILE__) + '/../'
require 'test/unit'
require 'epdfw'
require 'epdfdw'

include EideticPDF

class PageStyleTestCases < Test::Unit::TestCase
  def setup
    @ps_default = PageStyle.new
    @ps_default_landscape = PageStyle.new(:orientation => :landscape)
    @ps_letter_portrait = PageStyle.new(:page_size => :letter)
    @ps_letter_landscape = PageStyle.new(:page_size => :letter, :orientation => :landscape)
    @ps_legal_portrait = PageStyle.new(:page_size => :legal)
    @ps_legal_landscape = PageStyle.new(:page_size => :legal, :orientation => :landscape)
    @ps_A4_portrait = PageStyle.new(:page_size => :A4)
    @ps_A4_landscape = PageStyle.new(:page_size => :A4, :orientation => :landscape)
    @ps_B5_portrait = PageStyle.new(:page_size => :B5)
    @ps_B5_landscape = PageStyle.new(:page_size => :B5, :orientation => :landscape)
    @ps_C5_portrait = PageStyle.new(:page_size => :C5)
    @ps_C5_landscape = PageStyle.new(:page_size => :C5, :orientation => :landscape)
  end

  def assert_rectangle(x1, y1, x2, y2, rect)
    assert_equal(x1, rect.x1)
    assert_equal(y1, rect.y1)
    assert_equal(x2, rect.x2)
    assert_equal(y2, rect.y2)
  end

  def test_page_size
    assert_rectangle(0, 0, 612, 792, @ps_default.page_size)
    assert_rectangle(0, 0, 792, 612, @ps_default_landscape.page_size)
    assert_rectangle(0, 0, 612, 792, @ps_letter_portrait.page_size)
    assert_rectangle(0, 0, 792, 612, @ps_letter_landscape.page_size)
    assert_rectangle(0, 0, 612, 1008, @ps_legal_portrait.page_size)
    assert_rectangle(0, 0, 1008, 612, @ps_legal_landscape.page_size)
    assert_rectangle(0, 0, 595, 842, @ps_A4_portrait.page_size)
    assert_rectangle(0, 0, 842, 595, @ps_A4_landscape.page_size)
    assert_rectangle(0, 0, 499, 708, @ps_B5_portrait.page_size)
    assert_rectangle(0, 0, 708, 499, @ps_B5_landscape.page_size)
    assert_rectangle(0, 0, 459, 649, @ps_C5_portrait.page_size)
    assert_rectangle(0, 0, 649, 459, @ps_C5_landscape.page_size)
  end

  def test_crop_size
    assert_rectangle(0, 0, 612, 792, @ps_default.crop_size)
    assert_rectangle(0, 0, 792, 612, @ps_default_landscape.crop_size)
    assert_rectangle(0, 0, 612, 792, @ps_letter_portrait.crop_size)
    assert_rectangle(0, 0, 792, 612, @ps_letter_landscape.crop_size)
    assert_rectangle(0, 0, 612, 1008, @ps_legal_portrait.crop_size)
    assert_rectangle(0, 0, 1008, 612, @ps_legal_landscape.crop_size)
    assert_rectangle(0, 0, 595, 842, @ps_A4_portrait.crop_size)
    assert_rectangle(0, 0, 842, 595, @ps_A4_landscape.crop_size)
    assert_rectangle(0, 0, 499, 708, @ps_B5_portrait.crop_size)
    assert_rectangle(0, 0, 708, 499, @ps_B5_landscape.crop_size)
    assert_rectangle(0, 0, 459, 649, @ps_C5_portrait.crop_size)
    assert_rectangle(0, 0, 649, 459, @ps_C5_landscape.crop_size)
  end

  def test_orientation
    assert_equal(:portrait, @ps_default.orientation)
    assert_equal(:landscape, @ps_default_landscape.orientation)
    assert_equal(:portrait, @ps_letter_portrait.orientation)
    assert_equal(:landscape, @ps_letter_landscape.orientation)
    assert_equal(:portrait, @ps_legal_portrait.orientation)
    assert_equal(:landscape, @ps_legal_landscape.orientation)
    assert_equal(:portrait, @ps_A4_portrait.orientation)
    assert_equal(:landscape, @ps_A4_landscape.orientation)
    assert_equal(:portrait, @ps_B5_portrait.orientation)
    assert_equal(:landscape, @ps_B5_landscape.orientation)
    assert_equal(:portrait, @ps_C5_portrait.orientation)
    assert_equal(:landscape, @ps_C5_landscape.orientation)
  end

  def test_landscape
    assert_equal(false, @ps_default.landscape)
    assert_equal(true, @ps_default_landscape.landscape)
    assert_equal(false, @ps_letter_portrait.landscape)
    assert_equal(true, @ps_letter_landscape.landscape)
    assert_equal(false, @ps_legal_portrait.landscape)
    assert_equal(true, @ps_legal_landscape.landscape)
    assert_equal(false, @ps_A4_portrait.landscape)
    assert_equal(true, @ps_A4_landscape.landscape)
    assert_equal(false, @ps_B5_portrait.landscape)
    assert_equal(true, @ps_B5_landscape.landscape)
    assert_equal(false, @ps_C5_portrait.landscape)
    assert_equal(true, @ps_C5_landscape.landscape)
  end
end

class PageWriterTestCases < Test::Unit::TestCase
  def setup
    @doc = DocumentWriter.new
    @doc.open
    @page = @doc.open_page
  end

  def teardown
    @page.close
    @doc.close
  end

  def test_units
    [:pt, :cm, :in].each do |units|
      @page.units(units)
      assert_equal(units, @page.units)
    end
  end
end

def assert_array_in_delta(expected_floats, actual_floats, delta)
  expected_floats.each_with_index { |e, i| assert_in_delta(e, actual_floats[i], delta) }
end

def assert_close(expected, actual)
  if expected.respond_to?(:each_with_index) and actual.respond_to?(:[])
    expected.each_with_index { |e, i| assert_in_delta(e, actual[i], 2 ** -20) }
  else
    assert_in_delta(expected, actual, 2 ** -20)
  end
end
