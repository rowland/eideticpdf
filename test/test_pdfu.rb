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
    d = PdfDictionary.new.update(h)
    assert_equal("<<\n/baz 7 \n/foo (bar) \n>>\n", d.to_s)
  end
end

class PdfDictionaryObjectTestCases < Test::Unit::TestCase
  def test_body
    h = {
      'foo' => PdfString.new('bar'),
      'baz' => PdfInteger.new(7)
    }
    pdo = PdfDictionaryObject.new(1,0)
    pdo.dictionary.update(h)
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
