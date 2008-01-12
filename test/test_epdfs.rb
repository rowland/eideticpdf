#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2008-01-12.
#  Copyright (c) 2008, Eidetic Software. All rights reserved.

$: << File.dirname(__FILE__) + '/../'
require 'test/unit'
require 'epdfs'

include EideticPDF

class NumericTestCases < Test::Unit::TestCase
  def test_degrees
    assert_equal(Math::PI, 180.degrees)
  end
  
  def test_even?
    assert(2.even?, "2 is even")
    assert(!1.even?, "1 is not even")
  end
  
  def test_odd?
    assert(1.odd?, "1 is odd")
    assert(!2.odd?, "2 is not odd")
  end
end

class StatisticsTestCases < Test::Unit::TestCase
  def setup
    @ary = [2, 3].extend(Statistics)
  end

  def test_sum
    assert_equal(5, @ary.sum)
  end

  def test_mean
    assert_equal(2.5, @ary.mean)
  end
end

class JpegInfoTestCases < Test::Unit::TestCase
  def setup
    @@image ||= IO.read(File.join(File.dirname(__FILE__), "testimg.jpg"))
  end

  def test_jpeg?
    assert JpegInfo.jpeg?(@@image)
  end

  def test_jpeg_dimensions
    assert_equal([227, 149, 3, 8], JpegInfo.jpeg_dimensions(@@image))
  end
end
