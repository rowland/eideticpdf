#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-12-18.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

$: << File.dirname(__FILE__) + '/../'
require 'test/unit'
require 'epdfafm'

include EideticPDF::AFM

class AdobeFontMetricsTestCases < Test::Unit::TestCase
  def test_from_file
    afm = AdobeFontMetrics.load(File.join(File.dirname(__FILE__), '..', 'fonts', 'Courier.afm'))
    assert_equal('space', afm.char_metrics['space'].name)
    assert_equal(32, afm.char_metrics['space'].code)
    assert_equal(600, afm.char_metrics['space'].width)
  end
end
