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
  end

  class PdfInteger
    attr_reader :value
    
    def initialize(value)
      @value = value.to_i
    end
    
    def to_s
      "#{value} "
    end

    def eql?(other)
      self.value.eql?(other.value)
    end
    
    def ==(other)
      self.value == other.value
    end
  end

  class PdfReal
    attr_reader :value
    
    def initialize(value)
      @value = value.to_f
    end
    
    def to_s
      "#{value} "
    end
  end

  # text written between ()'s with '(', ')', and '\' escaped with '\'
  class PdfString
    attr_reader :value
    
    def initialize(value)
      @value = value.to_s
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
      self.name == other.name
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
  private        
    def wrapped_values
      # return values.join if @wrap.nil? or @wrap.zero?
      self.map { |segment| segment.join }.join("\n")
    end
  end
  
  class PdfDictionary
    def initialize
      @hash = {}
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
end
