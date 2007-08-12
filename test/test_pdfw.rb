#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-07-14.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

$: << File.dirname(__FILE__) + '/../'
require 'test/unit'
require 'pdfw'

include PdfW

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
    assert_rectangle(0, 0, 499, 70, @ps_B5_portrait.page_size)
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
    assert_rectangle(0, 0, 499, 70, @ps_B5_portrait.crop_size)
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
