#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-07-13.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

module PdfU
  class Header
    VERSIONS = {
      1.0 => '%PDF-1.0',
      1.1 => '%PDF-1.1',
      1.2 => '%PDF-1.2',
      1.3 => '%PDF-1.3'
    }

    def initialize(version=1.3)
      @version = version
    end

    def to_s
      VERSIONS[@version]
    end
  end
    
  class IndirectObjectRef
    attr_reader :indirect_object
    
    def initialize(indirect_object)
      @indirect_object = indirect_object
    end
    
    def to_s
      @indirect_object.reference_string
    end
  end

  class IndirectObject
    attr_reader :seq, :gen

    def initialize(seq, gen, obj=nil)
      @seq, @gen, @obj = seq, gen, obj
    end

    def header
      "#{@seq} #{@gen} obj\n"
    end

    def body
      @obj ? "#{@obj}\n" : ''
    end

    def footer
      "endobj\n"
    end

    def to_s
      header + body + footer
    end

    def reference_string
      "#{@seq} #{@gen} R "
    end

    def reference_object
      IndirectObjectRef.new(self)
    end
  end

  # direct objects
  class PdfBoolean
    attr_reader :value
    
    def initialize(value)
      @value = value
    end
    
    def to_s
      value ? 'true ' : 'false '
    end
    
    def ==(other)
      other.respond_to?(:value) && self.value == other.value
    end
  end
  
  class PdfNumber
    def to_s
      "#{value} "
    end

    def eql?(other)
      self.value.eql?(other.value)
    end

    def ==(other)
      other.respond_to?(:value) && self.value == other.value
    end
  end

  class PdfInteger < PdfNumber
    attr_reader :value

    def initialize(value)
      @value = value.to_i
    end

    def self.ary(int_ary)
      p_ary = int_ary.map do |i|
        if i.respond_to?(:to_i)
          PdfInteger.new(i.to_i)
        elsif i.respond_to?(:to_ary)
          PdfInteger.ary(i.to_ary)
        else
          i
        end
      end
      PdfArray.new p_ary
    end
  end

  class PdfReal < PdfNumber
    attr_reader :value

    def initialize(value)
      @value = value.to_f
    end

    def self.ary(float_ary)
      p_ary = float_ary.map do |f|
        if f.respond_to?(:to_f)
          PdfReal.new(f.to_f)
        elsif f.respond_to?(:to_ary)
          PdfReal.ary(f.to_ary)
        else
          f
        end
      end
      PdfArray.new p_ary
    end
  end

  # text written between ()'s with '(', ')', and '\' escaped with '\'
  class PdfString
    attr_reader :value
    
    def initialize(value)
      @value = value.to_s
    end

    def eql?(other)
      self.value.eql?(other.value)
    end

    def ==(other)
      other.respond_to?(:value) && self.value == other.value
    end
    
    def to_s
      "(#{PdfString.escape(value)}) "
    end
    
    def self.escape(string)
      #string.gsub(/[()\\]/,"\\\\1")
      string.gsub('\\','\\\\\\').gsub('(','\\(').gsub(')','\\)')
    end
  end

  # name of PDF entity, written as /Name
  class PdfName
    attr_reader :name

    def initialize(name)
      @name = name.to_s
    end

    def to_s
      "/#{name} "
    end

    def hash
      self.to_s.hash
    end

    def eql?(other)
      self.name.eql?(other.name)
    end

    def ==(other)
      other.respond_to?(:name) && self.name == other.name
    end
  end

  class PdfArray
    include Enumerable

    attr_reader :values
    attr_accessor :wrap

    def initialize(values=[], wrap=0)
      @values, @wrap = values, wrap
    end

    def to_s
      "[#{wrapped_values}] "
    end

    def each
      if wrap.zero?
        yield values
      else
        0.step(values.size, wrap) { |i| yield values[i, wrap] }
      end
    end

    def eql?(other)
      self.values.eql?(other.values) && self.wrap.eql?(other.wrap)
    end

    def ==(other)
      (other.respond_to?(:values) && self.values == other.values) &&
      (other.respond_to?(:wrap) && self.wrap == other.wrap)
    end

  private        
    def wrapped_values
      # return values.join if @wrap.nil? or @wrap.zero?
      self.map { |segment| segment.join }.join("\n")
    end
  end

  class PdfDictionary
    def initialize(other={})
      @hash = {}
      update(other)
    end

    def [](key)
      @hash[name_from_key(key)]
    end

    def []=(key, value)
      @hash[name_from_key(key)] = value
    end

    def update(other)
      other.each_pair { |key, value| self[key] = value }
      self
    end

    def to_s
      s = "<<\n"
      # Sort the results consistently to be test-friendly.
      s << @hash.keys.sort { |a,b| a.to_s <=> b.to_s }.map { |key| "#{key}#{@hash[key]}\n" }.join
      s << ">>\n"
    end

  private
    def name_from_key(key)
      key.is_a?(PdfName) ? key : PdfName.new(key)
    end
  end
  
  class PdfDictionaryObject < IndirectObject
    def initialize(seq, gen)
      super(seq, gen, PdfDictionary.new)
    end
    
    def dictionary
      @obj
    end
    
    def body
      dictionary.to_s
    end
  end
  
  class PdfStream < PdfDictionaryObject
    attr_reader :stream

    def initialize(seq, gen, stream=nil)
      super(seq, gen)
      @stream = (stream || '').dup
    end

    def length=(length)
      dictionary['Length'] = PdfInteger.new(length)
    end

    def filter=(filter)
      if filter.is_a?(PdfArray)
        dictionary['Filter'] = filter
      else
        dictionary['Filter'] = PdfName.new(filter)
      end
    end

    def body
      "#{super}stream\n#{stream}endstream\n"
    end
  end
  
  class PdfNull
    def to_s
      "null "
    end
  end
  
  class InUseXRefEntry
    def initialize(byte_offset, gen)
      @byte_offset, @gen = byte_offset, gen
    end
    
    def to_s
      "%.10d %.5d n\n" % [@byte_offset, @gen]
    end
  end
  
  class FreeXRefEntry < IndirectObject
    attr_reader :seq, :gen

    def to_s
      "%.10d %.5d f\n" % [seq, gen]
    end
  end

  # sub-section of a cross-reference table
  class XRefSubSection < Array
    def initialize
      self << FreeXRefEntry.new(0,65535)
    end

    def to_s
      "#{self.first.seq} #{self.size}\n" << super
    end
  end

  # cross-reference table, allows quick access to any object in body
  class XRefTable < Array
    def size
      self.inject(0) { |size, ary| size + ary.size }
    end

    def to_s
      "xref\n" << self.map { |entry| entry.to_s }.join
    end
  end

  # list of indirect objects
  class Body < Array
    def write_and_xref(s, xref_sub_section)
      self.each do |indirect_object|
        xref_sub_section << InUseXRefEntry.new(s.length, indirect_object.gen)
        s << indirect_object.to_s
      end
      s
    end
  end

  # root object of a PDF document, with pointers to other top-level objects
  class PdfCatalog < PdfDictionaryObject
    attr_reader :page_mode, :pages, :outlines

    def initialize(seq, gen, page_mode=:use_none, pages=nil, outlines=nil)
      super(seq, gen)
      dictionary['Type'] = PdfName.new('Catalog')
      @page_mode  = page_mode
      dictionary['PageMode'] = PdfName.new(PAGE_MODES[page_mode])
      if pages
        @pages = pages.indirect_object
        dictionary['Pages'] = pages
      end
      if outlines
        @outlines = outlines.indirect_object
        dictionary['Outlines'] = outlines
      end
    end

    def to_s
      super
    end

    PAGE_MODES = {
      :use_none => 'UseNone',
      :use_outlines => 'UseOutlines',
      :use_thumbs => 'UseThumbs',
      :full_screen => 'FullScreen'
    }.freeze
  end

  class Trailer < PdfDictionary
    attr_accessor :xref_table_start
    attr_reader :xref_table_size

    def xref_table_size=(size)
      self['Size'] = PdfInteger.new(size)
    end

    def to_s
      s = "trailer\n"
      s << super
      s << "startxref\n"
      s << "#{xref_table_start}\n"
      s << "%%EOF\n"
    end
  end

  class Rectangle < Array
    attr_reader :x1, :y1, :x2, :y2

    def initialize(x1, y1, x2, y2)
      @x1, @y1, @x2, @y2 = x1, y1, x2, y2
      self << PdfInteger.new(x1) << PdfInteger.new(y1) << PdfInteger.new(x2) << PdfInteger.new(y2)
    end
  end

  # defines Type1, TrueType, etc font
  class PdfFont <  PdfDictionaryObject
    def enoding=(encoding)
      encoding = PdfName.new(encoding) if encoding.is_a?(String)
      dictionary['Encoding'] = encoding        
    end

    def widths=(widths)
      dictionary['Widths'] = widths
    end

    def font_descriptor=(font_descriptor)
      dictionary['FontDescriptor'] = font_descriptor
    end

    def initialize(seq, gen, sub_type, base_font, first_char, last_char, widths, font_descriptor)
      super(seq, gen)
        dictionary['Type'] = PdfName.new('Font')
        dictionary['Subtype'] = PdfName.new(sub_type)
        dictionary['BaseFont'] = PdfName.new(base_font)
        dictionary['FirstChar'] = PdfInteger.new(first_char)
        dictionary['LastChar'] = PdfInteger.new(last_char)
        dictionary['Widths'] = widths unless widths.nil?
        dictionary['FontDescriptor'] = font_descriptor unless font_descriptor.nil?
    end
  end

  class PdfFontDescriptor < PdfDictionaryObject
    def initialize(seq, gen,
      font_name, flags, font_b_box, missing_width, stem_v, stem_h, italic_angle, 
      cap_height, x_height, 
      ascent, descent, leading, 
      max_width, avg_width)
      super(seq, gen)
      dictionary['Type'] = PdfName.new('FontDescriptor')
      dictionary['FontName'] = PdfName.new(font_name)
      dictionary['Flags'] = PdfInteger.new(flags)
      dictionary['FontBBox'] = PdfArray.new(font_b_box.map { |i| PdfInteger.new(i) })
      dictionary['MissingWidth'] = PdfInteger.new(missing_width)
      dictionary['StemV'] = PdfInteger.new(stem_v)
      dictionary['StemH'] = PdfInteger.new(stem_h)
      dictionary['ItalicAngle'] = PdfReal.new(italic_angle)
      dictionary['CapHeight'] = PdfInteger.new(cap_height)
      dictionary['XHeight'] = PdfInteger.new(x_height)
      dictionary['Ascent'] = PdfInteger.new(ascent)
      dictionary['Descent'] = PdfInteger.new(descent)
      dictionary['Leading'] = PdfInteger.new(leading)
      dictionary['MaxWidth'] = PdfInteger.new(max_width)
      dictionary['AvgWidth'] = PdfInteger.new(avg_width)
    end
  end

  class PdfFontEncoding < PdfDictionaryObject
    def initialize(seq, gen, base_encoding, differences)
      super(seq, gen)
      dictionary['Type'] = PdfName.new('Encoding')
      dictionary['BaseEncoding'] = PdfName.new(base_encoding)
      dictionary['Differences'] = differences
    end
  end
  
  # images and forms
  class PdfXObject < PdfStream
    def initialize(seq, gen, stream=nil)
      super(seq, gen, stream)
      dictionary['Type'] = PdfName.new('XObject')
    end
  end
  
  class PdfImage < PdfXObject
    attr_reader :width, :height

    def initialize(seq, gen, stream=nil)
      super(seq, gen, stream)
      dictionary['Subtype'] = PdfName.new('Image')
    end

    def body
      dictionary['Length'] = PdfInteger.new(stream.length)
      super
    end

    def filter=(filter)
      dictionary['Filter'] = PdfName.new(filter)
    end

    def filters=(filters)
      dictionary['Filter'] = filters
    end

    def width=(width)
      @width = width
      dictionary['Width'] = PdfInteger.new(width)
    end

    def height=(height)
      @height = height
      dictionary['Height'] = PdfInteger.new(height)
    end

    def bits_per_component=(bits)
      dictionary['BitsPerComponent'] = PdfInteger.new(bits)
    end

    def color_space=(color_space)
      if color_space.is_a?(String)
        dictionary['ColorSpace'] = PdfName.new(color_space)
      else
        # array or dictionary
        dictionary['ColorSpace'] = color_space
      end
    end

    def decode=(decode)
      dictionary['Decode'] = decode
    end

    def interpolate=(interpolate)
      dictionary['Interpolate'] = PdfBoolean.new(interpolate)
    end

    def image_mask=(image_mask)
      dictionary['ImageMask'] = PdfBoolean.new(image_mask)
    end

    def intent=(intent)
      dictionary['Intent'] = PdfName.new(intent)
    end
  end
  
  class PdfAnnot < PdfDictionaryObject
    def initialize(seq, gen, sub_type, rect)
      super(seq, gen)
      dictionary['Type'] = PdfName.new('Annot')
      dictionary['Subtype'] = PdfName.new(sub_type)
      dictionary['Rect'] = rect
    end

    def border=(border)
      dictionary['Border'] = PdfInteger.ary(border)
    end

    def color=(color)
      dictionary['C'] = PdfReal.ary(color)
    end

    def title=(title)
      dictionary['T'] = PdfString.new(title)
    end

    def mod_date=(mod_date)
      dictionary['M'] = PdfString.new(mod_date.strftime("%Y%m%d%H%M%S"))
    end

    def flags=(flags)
      dictionary['F'] = PdfInteger.new(flags)
    end

    def highlight=(highlight)
      dictionary['H'] = PdfName.new(highlights[highlight] || highlight)
    end

    def border_style=(border_style)
      dictionary['BS'] = PdfDictionary.new(border_style)
    end

    def appearance_dictionary=(appearance)
      dictionary['AP'] = PdfDictionary.new(appearance)
    end

    def appearance_state=(state)
      dictionary['AS'] = PdfName.new(state)
    end
  
  private
    def highlights
      @highlights ||= {
        :none => 'N',
        :invert => 'I',
        :outline => 'O',
        :push => 'P'
      }
    end
  end  
end
