#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-12-18.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

$: << File.dirname(__FILE__) + '/../'
require 'test/unit'
require 'epdfafm'

include EideticPDF::AFM

class AdobeFontMetricsTestCases < Test::Unit::TestCase
  FontDir        = File.join(File.dirname(__FILE__), '..', 'fonts')
  CourierAfmFile = File.join(FontDir, 'Courier.afm')

  def test_from_array
    courier_ary = IO.readlines(CourierAfmFile)
    afm = AdobeFontMetrics.new.load_afm(courier_ary)
    ch = afm.chars_by_name['space']
    assert_equal('space', ch.name)
    assert_equal(32, ch.code)
    assert_equal(600, ch.width)
  end

  def test_from_file
    afm = AdobeFontMetrics.load(CourierAfmFile)
    ch = afm.chars_by_name['space']
    assert_equal('space', ch.name)
    assert_equal(32, ch.code)
    assert_equal(600, ch.width)
  end

  def test_afm_cache
    assert_equal(77, AdobeFontMetrics.afm_cache.size)
  end

  def test_find_font
    afm = AdobeFontMetrics.find_font('Helvetica-BoldOblique')
    assert_not_nil(afm)
    assert_equal('Helvetica-BoldOblique', afm.font_name, "font_name")
    assert_equal('Helvetica Bold Oblique', afm.full_name, "full_name")
    assert_equal('Helvetica', afm.family_name, "family_name")
    assert_equal('Bold', afm.weight, "weight")
    assert_equal(-12, afm.italic_angle, "italic_angle")
    assert_equal(false, afm.is_fixed_pitch, "is_fixed_pitch")
    assert_equal(0x40060, afm.flags, "flags")
    assert_equal([-174, -228, 1114, 962], afm.font_b_box, "font_b_box")
    assert_equal(-100, afm.underline_position, "underline_position")
    assert_equal(50, afm.underline_thickness, "underline_thickness")
    assert_equal('002.000', afm.version, "version")
    assert_equal('Copyright (c) 1985, 1987, 1989, 1990, 1997 Adobe Systems Incorporated.  All Rights Reserved.Helvetica is a trademark of Linotype-Hell AG and/or its subsidiaries.', afm.notice)
    assert_equal('ExtendedRoman', afm.character_set, "character_set")
    assert_equal('AdobeStandardEncoding', afm.encoding_scheme, "encoding_scheme")
    assert_equal(718, afm.cap_height, "cap_height")
    assert_equal(532, afm.x_height, "x_height")
    assert_equal(718, afm.ascender, "ascender")
    assert_equal(-207, afm.descender, "descender")
    assert_equal(118, afm.std_h_w, "std_h_w")
    assert_equal(140, afm.std_v_w, "std_v_w")
    assert_equal(315, afm.chars_by_name.size, "char_metrics.size")
    ch = afm.chars_by_name['Euro']
    assert_equal(-1, ch.code)
    assert_equal(556, ch.width)
  end

  def test_find_fonts
    helv = AdobeFontMetrics.find_fonts(:family_name => 'Helvetica')
    assert_equal(12, helv.size)
    demi = AdobeFontMetrics.find_fonts(:weight => 'Demi')
    assert_equal(6, demi.size)
    italic = AdobeFontMetrics.find_fonts(:italic => true)
    assert_equal(35, italic.size)
  end

  def test_font_weights
    assert_equal(['Demi', 'Light'], font_weights('ITC Bookman'))
    assert_equal(['Bold', 'Medium'], font_weights('Palatino'))
  end

  def test_font_names
    assert_equal('ZapfDingbats', font_names.last)
  end

  def test_codepoints_for_encoding
    codepoints = Codepoints.for_encoding('WinAnsiEncoding')
    assert_equal(32, codepoints[32])
    assert_equal(65, codepoints[65])
  end

  def test_glyphs_for_codepoints
    assert_equal(['space', 'A'], Glyphs.for_codepoints([32,65]))
  end

  def test_glyphs_for_encoding
    glyphs = Glyphs.for_encoding('WinAnsiEncoding')
    assert_equal(256, glyphs.size, "Wrong number of glyphs")
    assert_equal('space', glyphs[32])
    assert_equal('A', glyphs[65])
  end

  def test_widths_for_glyphs
    afm = AdobeFontMetrics.find_font('Helvetica-BoldOblique')
    assert_not_nil(afm, "Font not found.")
    glyphs = Glyphs.for_encoding('WinAnsiEncoding')
    widths = Glyphs.widths_for_glyphs(glyphs, afm.chars_by_name)
    assert_equal(278, widths[32])
    assert_equal(722, widths[65])
  end

  def test_widths_for_encoding
    afm = AdobeFontMetrics.find_font('Helvetica-BoldOblique')
    assert_not_nil(afm, "Font not found.")
    widths = Glyphs.widths_for_encoding('WinAnsiEncoding', afm.chars_by_name)
    assert_equal(278, widths[32])
    assert_equal(722, widths[65])
  end

  def test_font_metrics1
    families = ['Courier', 'Helvetica', 'Times']
    weights = [false, 'Bold']
    italics = [false, true]
    families.each do |family|
      weights.each do |weight|
        italics.each do |italic|
          fm = font_metrics(family, :weight => weight, :italic => italic)
          assert_not_nil(fm, "Should never return nil.")
          assert_equal(AdobeFontMetrics::NonSymbolic, fm.flags & AdobeFontMetrics::NonSymbolic, "#{family}: NonSymbolic")
          assert_equal(italic ? AdobeFontMetrics::Italic : 0, fm.flags & AdobeFontMetrics::Italic, "#{family}: Italic test")
          assert_equal(family == 'Courier' ? AdobeFontMetrics::FixedPitch : 0, fm.flags & AdobeFontMetrics::FixedPitch, "#{family}: Fixed Pitch test")
        end
      end
    end
  end

  def test_font_metrics2
    symbol = font_metrics('Symbol')
    assert_not_nil(symbol)
    assert_equal(189, symbol.widths.select { |w| w != 0 }.size) # apple symbol not mapped by default
    assert_equal(750, symbol.ascent, "ascent")
    assert_equal(-188, symbol.descent, "descent")

    zapf = font_metrics('ZapfDingbats')
    assert_not_nil(zapf)
    assert_equal(202, zapf.widths.select { |w| w != 0 }.size)
    assert_equal(750, zapf.ascent, "ascent")
    assert_equal(-188, zapf.descent, "descent")
  end

  def test_font_metrics3
    fm = font_metrics('Helvetica', :style => 'Italic', :weight => 'Bold', :encoding => 'CP1250')
    assert_not_nil(fm)
    assert_equal(256, fm.widths.size)
    assert_equal(278, fm.widths[32])
    assert_equal(722, fm.widths[65])
    assert_not_nil(fm.differences)
    assert_equal(77, fm.differences.values.size)
  end
end
