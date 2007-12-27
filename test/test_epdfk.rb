#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-11-03.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

$: << File.dirname(__FILE__) + '/../'
require 'test/unit'
require 'epdfk'

include EideticPDF

class PdfKTestCases < Test::Unit::TestCase
  def test_font_index
    assert_equal(0, PdfK::font_index('Helvetica'))
    assert_equal(11, PdfK::font_index('Courier-BoldOblique'))
  end

  def test_font_metrics
    assert_not_nil(PdfK::font_metrics('Helvetica'))
    assert_raise(Exception) { PdfK::font_metrics('BogusFontName') }
  end
end

class FontMetricsTestCases < Test::Unit::TestCase
  def setup
    @metrics0 = PdfK::font_metrics('Helvetica')
    @metrics11 = PdfK::font_metrics('Courier-BoldOblique')
  end

  def test_widths
    assert_equal(191, @metrics0.widths[39])
    assert_equal(600, @metrics11.widths[39])
  end
end
