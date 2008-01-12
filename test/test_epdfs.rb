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
