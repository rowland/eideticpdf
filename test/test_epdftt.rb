#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-11-03.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

$: << File.dirname(__FILE__) + '/../'
require 'test/unit'
require 'epdftt'

include EideticPDF

class PdfTTTestCases < Test::Unit::TestCase
  def test_font_index
    assert_equal(0, PdfTT::font_index('Arial'))
    assert_equal(11, PdfTT::font_index('CourierNew,BoldItalic'))
  end

  def test_font_metrics
    assert_not_nil(PdfTT::font_metrics('Arial'))
    assert_raise(Exception) { PdfTT::font_metrics('BogusFontName') }
  end
end

class PdfTT_FontMetricsTestCases < Test::Unit::TestCase
  def setup
    @metrics0 = PdfTT::font_metrics('Arial')
    @metrics11 = PdfTT::font_metrics('CourierNew,BoldItalic')
  end

  def test_widths
    assert_equal(191, @metrics0.widths[39])
    assert_equal(600, @metrics11.widths[39])
  end
end
