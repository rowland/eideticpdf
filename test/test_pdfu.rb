#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-07-14.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

$: << File.dirname(__FILE__) + '/../'
require 'test/unit'
require 'pdfu'

include PdfU

class HeaderTestCases < Test::Unit::TestCase
  def setup
    @header = Header.new
    @header11 = Header.new(1.1)
  end

  def test_to_s
    assert_equal('%PDF-1.3', @header.to_s)
    assert_equal('%PDF-1.1', @header11.to_s)
  end
end

class IndirectObjectRefTestCases < Test::Unit::TestCase
  def test_to_s
    io = IndirectObject.new(1,0)
    ior = IndirectObjectRef.new(io)
    assert_equal("1 0 R ", ior.to_s)
  end
end

class IndirectObjectTestCases < Test::Unit::TestCase
  def setup
    @io = IndirectObject.new(1,0)
  end
  
  def test_header
    assert_equal("1 0 obj\n", @io.header)
  end
  
  def test_body
    assert_equal('', @io.body)
  end
  
  def test_footer
    assert_equal("endobj\n", @io.footer)
  end
  
  def test_to_s
    assert_equal("1 0 obj\n" + "endobj\n", @io.to_s)
  end
end

class PdfBooleanTestCases < Test::Unit::TestCase
  def setup
    @t = PdfBoolean.new(true)
    @f = PdfBoolean.new(false)
  end
  
  def test_to_s
    assert_equal('true ', @t.to_s)
    assert_equal('false ', @f.to_s)
  end
end

class PdfIntegerTestCases < Test::Unit::TestCase
  def test_to_s
    seven = PdfInteger.new(7)
    assert_equal('7 ', seven.to_s)
  end

  def test_ary1
    a = PdfInteger.ary([1, 2, 3])
    assert_equal("[1 2 3 ] ", a.to_s)
  end

  def test_ary2
    a = PdfInteger.ary([1, 2, [3, 4]])
    assert_equal("[1 2 [3 4 ] ] ", a.to_s)
  end
end

class PdfRealTestCases < Test::Unit::TestCase
  def test_to_s
    five_five = PdfReal.new(5.5)
    assert_equal('5.5 ', five_five.to_s)
  end
end

class PdfStringTestCases < Test::Unit::TestCase
  def test_to_s
    string = PdfString.new('a\b(cd)')
    assert_equal(%q/(a\\\\b\(cd\)) /, string.to_s)
  end
  
  def test_escape
    assert_equal('a\\\\b\(cd\)', PdfString.escape('a\\b(cd)'))
  end
end

class PdfNameTestCases < Test::Unit::TestCase
  def test_to_s
    name = PdfName.new('name')
    assert_equal('/name ', name.to_s)
  end
end

class PdfArrayTestCases < Test::Unit::TestCase
  def setup
    @ary1 = PdfArray.new([1, 2, 3, 4, 5])
    @ary2 = PdfArray.new([1, 2, 3, 4, 5], 3)
  end

  def test_to_s
    assert_equal("[12345] ", @ary1.to_s)
    assert_equal("[123\n45] ", @ary2.to_s)
  end
end

class PdfDictionaryTestCases < Test::Unit::TestCase
  def test_to_s
    h = {
      PdfName.new('foo') => PdfString.new('bar'),
      PdfName.new('baz') => PdfInteger.new(7)
    }
    d = PdfDictionary.new(h)
    assert_equal("<<\n/baz 7 \n/foo (bar) \n>>\n", d.to_s)
  end
end

class PdfDictionaryObjectTestCases < Test::Unit::TestCase
  def test_body
    h = {
      'foo' => PdfString.new('bar'),
      'baz' => PdfInteger.new(7)
    }
    pdo = PdfDictionaryObject.new(1,0,h)
    assert_equal("<<\n/baz 7 \n/foo (bar) \n>>\n", pdo.body)
  end
end

class PdfStreamTestCases < Test::Unit::TestCase
  def setup
    @ps = PdfStream.new(1,0,'test')
    @ps.length = 4
    @ps.filter = 'bogus'
  end

  def test_length
    assert_equal(PdfInteger.new(4), @ps.dictionary['Length'])
  end

  def test_filter
    assert_equal(PdfName.new('bogus'), @ps.dictionary['Filter'])
  end

  def test_body
    assert_equal("<<\n/Filter /bogus \n/Length 4 \n>>\nstream\ntestendstream\n", @ps.body)
  end

  def test_to_s
    assert_equal("1 0 obj\n<<\n/Filter /bogus \n/Length 4 \n>>\nstream\ntestendstream\nendobj\n", @ps.to_s)
  end
end

class PdfNullTestCases < Test::Unit::TestCase
  def test_to_s
    null = PdfNull.new
    assert_equal("null ", null.to_s)
  end
end

class InUseXRefEntryTestCases < Test::Unit::TestCase
  def test_to_s
    entry = InUseXRefEntry.new(500,0)
    assert_equal("0000000500 00000 n\n", entry.to_s)
  end
end

class FreeXRefEntryTestCases < Test::Unit::TestCase
  def test_to_s
    entry = FreeXRefEntry.new(1,0)
    assert_equal("0000000001 00000 f\n", entry.to_s)
  end
end

class XRefSubSectionTestCases < Test::Unit::TestCase
  def setup
    @sub_section = XRefSubSection.new
    @sub_section << InUseXRefEntry.new(0,0)
    @sub_section << InUseXRefEntry.new(100,1)
  end

  def test_to_s
    assert_equal("0 3\n0000000000 65535 f\n0000000000 00000 n\n0000000100 00001 n\n", @sub_section.to_s)
  end
end

class XRefTableTestCases < Test::Unit::TestCase
  def setup
    @table = XRefTable.new
    @sub_section = XRefSubSection.new
    @sub_section << InUseXRefEntry.new(0,0)
    @sub_section << InUseXRefEntry.new(100,1)
    @table << @sub_section
  end

  def test_to_s
    assert_equal("xref\n0 3\n0000000000 65535 f\n0000000000 00000 n\n0000000100 00001 n\n", @table.to_s)
  end
end

class BodyTestCases < Test::Unit::TestCase
  def setup
    @io_int = IndirectObject.new(1,0,PdfInteger.new(7))
    @io_str = IndirectObject.new(2,0,PdfString.new("Hello"))
    @body = Body.new
  end
  
  def test_write_and_xref
    @body << @io_int << @io_str
    s = ''
    sub_section = XRefSubSection.new
    @body.write_and_xref(s, sub_section)
    assert_equal(@io_int.to_s + @io_str.to_s, s)
    assert_equal("0 3\n0000000000 65535 f\n0000000000 00000 n\n0000000018 00000 n\n", sub_section.to_s)
  end
end

class PdfCatalogTestCases < Test::Unit::TestCase
  def setup
    @cat = PdfCatalog.new(1,0) # xxx not finished here
  end

  def test_to_s
    assert_equal("1 0 obj\n<<\n/PageMode /UseNone \n/Type /Catalog \n>>\nendobj\n", @cat.to_s)
  end
end

class TrailerTestCases < Test::Unit::TestCase
  def setup
    @trailer = Trailer.new
    @trailer.xref_table_start = 0
    @trailer.xref_table_size = 3
  end

  def test_xref_table_size
    assert_equal(3, @trailer['Size'].value)
  end

  def test_to_s
    assert_equal("trailer\n<<\n/Size 3 \n>>\nstartxref\n0\n%%EOF\n", @trailer.to_s)
  end
end

class RectangleTestCases < Test::Unit::TestCase
  def setup
    @rect = Rectangle.new(1,2,3,4)
  end

  def test_attributes
    assert_equal(1, @rect.x1)
    assert_equal(2, @rect.y1)
    assert_equal(3, @rect.x2)
    assert_equal(4, @rect.y2)
  end

  def test_to_s
    assert_equal("1 2 3 4 ", @rect.to_s)
  end
end

module FontFactory
  def make_font_descriptor
    PdfFontDescriptor.new(100, 0,
      'ArialMT', 32, [-665, -325, 2029, 1006], 0, 0, 0, 0, 
      723, 525, 
      905, -212, 33, 
      2000, 0)
  end
end

class PdfFontTestCases < Test::Unit::TestCase
  include FontFactory

  def setup
    @widths = PdfArray.new([1, 3, 5, 7])
    @io_widths = IndirectObject.new(2, 0, @widths)
    @io_widths_ref = @io_widths.reference_object
    @font_descriptor = make_font_descriptor
    @font = PdfFont.new(1, 0, 'TrueType', 'ArialMT', 32, 169, @io_widths_ref, @font_descriptor.reference_object)
  end

  def test_to_s
    expected = "1 0 obj\n" << 
      "<<\n" <<
      "/BaseFont /ArialMT \n" <<
      "/FirstChar 32 \n" << 
      "/FontDescriptor 100 0 R \n" <<
      "/LastChar 169 \n" <<
      "/Subtype /TrueType \n" <<
      "/Type /Font \n" <<
      "/Widths 2 0 R \n" <<
      ">>\n" <<
      "endobj\n"
    assert_equal(expected, @font.to_s)
  end
end

class PdfFontDescriptorTestCases < Test::Unit::TestCase
  include FontFactory
  
  def setup
    @font_descriptor = make_font_descriptor
  end
  
  def test_to_s
    expected = "100 0 obj\n" <<
      "<<\n" << 
      "/Ascent 905 \n" << 
      "/AvgWidth 0 \n" << 
      "/CapHeight 723 \n" << 
      "/Descent -212 \n" << 
      "/Flags 32 \n" << 
      "/FontBBox [-665 -325 2029 1006 ] \n" << 
      "/FontName /ArialMT \n" << 
      "/ItalicAngle 0.0 \n" << 
      "/Leading 33 \n" << 
      "/MaxWidth 2000 \n" << 
      "/MissingWidth 0 \n" << 
      "/StemH 0 \n" << 
      "/StemV 0 \n" << 
      "/Type /FontDescriptor \n" << 
      "/XHeight 525 \n" << 
      ">>\n" << 
      "endobj\n"
    assert_equal(expected, @font_descriptor.to_s)
  end
end

class PdfFontEncodingTestCases < Test::Unit::TestCase
  def setup
    differences = PdfArray.new([PdfInteger.new(32), PdfName.new('space')])
    @font_encoding = PdfFontEncoding.new(1, 0, "MacRomanEncoding", differences)
  end

  def test_to_s
    expected = "1 0 obj\n" <<
      "<<\n" <<
      "/BaseEncoding /MacRomanEncoding \n" <<
      "/Differences [32 /space ] \n" <<
      "/Type /Encoding \n" <<
      ">>\n" <<
      "endobj\n"
    assert_equal(expected, @font_encoding.to_s)
  end
end

class PdfXObjectTestCases < Test::Unit::TestCase
  def test_initialize
    xobj = PdfXObject.new(1,0)
    assert_equal(PdfName.new('XObject'), xobj.dictionary['Type'])
  end
end

class PdfImageTestCases < Test::Unit::TestCase
  def setup
    @image = PdfImage.new(1,0,'test')
  end

  def test_initialize
    assert_equal(PdfName.new('XObject'), @image.dictionary['Type'])
    assert_equal(PdfName.new('Image'), @image.dictionary['Subtype'])
  end

  def test_body
    assert_equal("<<\n/Length 4 \n/Subtype /Image \n/Type /XObject \n>>\nstream\ntestendstream\n", @image.body)
    assert_equal(PdfInteger.new(4), @image.dictionary['Length'])
  end

  def test_filter=
    @image.filter = 'ASCIIHexDecode'
    assert_equal(PdfName.new('ASCIIHexDecode'), @image.dictionary['Filter'])
  end

  def test_filters=
    filters = PdfArray.new ['ASCII85Decode', 'LZWDecode'].map { |s| PdfName.new(s) }
    @image.filters = filters
    assert_equal(filters, @image.dictionary['Filter'])
  end

  def test_width
    @image.width = 320
    assert_equal(320, @image.width)
    assert_equal(PdfInteger.new(320), @image.dictionary['Width'])
  end

  def test_height
    @image.height = 200
    assert_equal(200, @image.height)
    assert_equal(PdfInteger.new(200), @image.dictionary['Height'])
  end

  def test_bits_per_component=
    @image.bits_per_component = 8
    assert_equal(PdfInteger.new(8), @image.dictionary['BitsPerComponent'])
  end

  def test_color_space=
    @image.color_space = 'DeviceCMYK'
    assert_equal(PdfName.new('DeviceCMYK'), @image.dictionary['ColorSpace'])
    # todo: test other types of values, such as indirect objects
  end

  def test_decode=
    decode = PdfArray.new [1, 0].map { |i| PdfInteger.new(i )}
    @image.decode = decode
    assert_equal(decode, @image.dictionary['Decode'])
  end

  def test_interpolate=
    @image.interpolate = true
    assert_equal(PdfBoolean.new(true), @image.dictionary['Interpolate'])
  end

  def test_image_mask=
    @image.image_mask = false
    assert_equal(PdfBoolean.new(false), @image.dictionary['ImageMask'])
  end

  def test_intent=
    @image.intent = 'AbsoluteColorimetric'
    assert_equal(PdfName.new('AbsoluteColorimetric'), @image.dictionary['Intent'])
  end
end  

class PdfAnnotTestCases < Test::Unit::TestCase
  def setup
    @rect = Rectangle.new(1,2,3,4)
    @annot = PdfAnnot.new(1, 0, 'Text', @rect)
  end

  def test_initialize
    assert_equal(1, @annot.seq)
    assert_equal(0, @annot.gen)
    assert_equal(PdfName.new('Annot'), @annot.dictionary['Type'])
    assert_equal(PdfName.new('Text'), @annot.dictionary['Subtype'])
    assert_equal(@rect, @annot.dictionary['Rect'])
  end

  def test_border=
    border = [0, 0, 1]
    @annot.border = border
    assert_equal(PdfInteger.ary(border), @annot.dictionary['Border'])
  end

  def test_color=
    color = [0.2, 0.4, 0.6]
    @annot.color = color
    assert_equal(PdfReal.ary(color), @annot.dictionary['C'])
  end

  def test_title=
    @annot.title = 'Joe'
    assert_equal(PdfString.new('Joe'), @annot.dictionary['T'])
  end

  def test_mod_date=
    t = Time.local(2007, 9, 8, 14, 30, 0, 0)
    @annot.mod_date = t
    assert_equal(PdfString.new('20070908143000'), @annot.dictionary['M'])
  end

  def test_flags=
    @annot.flags = 0
    assert_equal(PdfInteger.new(0), @annot.dictionary['F'])
  end

  def test_highlight=
    @annot.highlight = :none
    assert_equal(PdfName.new('N'), @annot.dictionary['H'])
    @annot.highlight = :invert
    assert_equal(PdfName.new('I'), @annot.dictionary['H'])
    @annot.highlight = :outline
    assert_equal(PdfName.new('O'), @annot.dictionary['H'])
    @annot.highlight = :push
    assert_equal(PdfName.new('P'), @annot.dictionary['H'])

    @annot.highlight = 'N'
    assert_equal(PdfName.new('N'), @annot.dictionary['H'])
    @annot.highlight = 'I'
    assert_equal(PdfName.new('I'), @annot.dictionary['H'])
    @annot.highlight = 'O'
    assert_equal(PdfName.new('O'), @annot.dictionary['H'])
    @annot.highlight = 'P'
    assert_equal(PdfName.new('P'), @annot.dictionary['H'])
  end

  def test_border_style=
    border_style = {
      'Type' => PdfName.new('Border'),
      'W' => PdfInteger.new(1),
      'S' => PdfName.new('D'),
      'D' => PdfInteger.ary([3, 2])
    }
    @annot.border_style = border_style
    assert_equal(PdfDictionary.new(border_style).to_s, @annot.dictionary['BS'].to_s)
  end

  def test_appearance_dictionary=
    io = IndirectObject.new(1,0)
    appearance = { 'N' => io.reference_object }
    @annot.appearance_dictionary = appearance
    assert_equal("<<\n/N 1 0 R \n>>\n", @annot.dictionary['AP'].to_s)
  end

  def test_appearance_state=
    @annot.appearance_state = 'Yes'
    assert_equal(PdfName.new('Yes'), @annot.dictionary['AS'])
  end
end  

class PdfTextAnnotTestCases < Test::Unit::TestCase
  def setup
    @rect = Rectangle.new(1,2,3,4)
    @annot = PdfTextAnnot.new(1, 0, @rect, 'Hello')
  end
  
  def test_initialize
    assert_equal(PdfName.new('Text'), @annot.dictionary['Subtype'])
    assert_equal(PdfString.new('Hello'), @annot.dictionary['Contents'])
  end
  
  def test_open=
    @annot.open = true
    assert_equal(PdfBoolean.new(true), @annot.dictionary['Open'])
    @annot.open = false
    assert_equal(PdfBoolean.new(false), @annot.dictionary['Open'])
  end
end

class PdfLinkAnnotTestCases < Test::Unit::TestCase
end

class PdfMovieAnnotTestCases < Test::Unit::TestCase
end

class PdfSoundAnnotTestCases < Test::Unit::TestCase
end

class PdfURIActionTestCases < Test::Unit::TestCase
end

class PdfAnnotBorderTestCases < Test::Unit::TestCase
end

class PdfResourcesTestCases < Test::Unit::TestCase
  def setup
    @res = PdfResources.new(1,0)
  end

  def test_proc_set=
    a = PdfName.ary ['PDF','Text','ImageB','ImageC']
    @res.proc_set = a
    assert_equal(a, @res.dictionary['ProcSet'])
  end
  
  def test_fonts
    io = IndirectObject.new(2,0)
    @res.fonts['F1'] = io.reference_object
    assert_equal("1 0 obj\n<<\n/Font <<\n/F1 2 0 R \n>>\n\n>>\nendobj\n", @res.to_s)
  end
  
  def test_x_objects
    io = IndirectObject.new(2,0)
    @res.x_objects['Im1'] = io.reference_object
    assert_equal("1 0 obj\n<<\n/XObject <<\n/Im1 2 0 R \n>>\n\n>>\nendobj\n", @res.to_s)
  end
end
