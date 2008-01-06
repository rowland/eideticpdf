#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-07-13.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

require 'epdfk'

module EideticPDF
  module PdfObjects
    class Header
      VERSIONS = {
        1.0 => "%PDF-1.0\n".freeze,
        1.1 => "%PDF-1.1\n".freeze,
        1.2 => "%PDF-1.2\n".freeze,
        1.3 => "%PDF-1.3\n".freeze,
        1.4 => "%PDF-1.4\n".freeze
      }

      def initialize(version=1.3)
        @version = version
      end

      def to_s
        VERSIONS[@version].dup
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

      def eql?(other)
        self.indirect_object.eql?(other.indirect_object)
      end

      def ==(other)
        other.respond_to?(:indirect_object) && self.indirect_object == other.indirect_object
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
      attr_reader :value
    
      def initialize(value)
        @value = value
      end

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
        string.gsub('\\','\\\\\\').gsub('(','\\(').gsub(')','\\)')
      end

      # TODO: What kind of changes are needed here?
      def self.escape_wide(string)
        string.gsub('\\','\\\\\\').gsub('(','\\(').gsub(')','\\)')
      end

      def self.ary(string_ary)
        p_ary = string_ary.map do |s|
          if s.respond_to?(:to_str)
            PdfString.new(s.to_str)
          elsif s.respond_to?(:to_ary)
            PdfString.ary(s.to_ary)
          else
            s
          end
        end
        PdfArray.new p_ary
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

      def self.ary(string_ary)
        p_ary = string_ary.map do |s|
          if s.respond_to?(:to_str)
            PdfName.new(s.to_str)
          elsif s.respond_to?(:to_ary)
            PdfName.ary(s.to_ary)
          else
            s
          end
        end
        PdfArray.new p_ary
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
      def initialize(hash={})
        @hash = {}
        update(hash)
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
      def initialize(seq, gen, hash={})
        super(seq, gen, PdfDictionary.new(hash))
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
        dictionary['Length'] = PdfInteger.new(length)
      end

      def length
        stream.length
      end

      def filter=(filter)
        if filter.is_a?(PdfArray)
          dictionary['Filter'] = filter
        else
          dictionary['Filter'] = PdfName.new(filter)
        end
      end

      def body
        dictionary['Length'] = PdfInteger.new(length)
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

    class Trailer < PdfDictionary
      attr_accessor :xref_table_start
      attr_reader :xref_table_size

      def xref_table_size=(size)
        @xref_table_size = size
        self['Size'] = PdfInteger.new(size)
      end
    
      def root=(root)
        self['Root'] = root.reference_object
      end

      def to_s
        s = "trailer\n"
        s << super
        s << "startxref\n"
        s << "#{xref_table_start}\n"
        s << "%%EOF\n"
      end
    end

    class Rectangle < PdfArray
      attr_reader :x1, :y1, :x2, :y2

      def initialize(x1, y1, x2, y2)
        super([x1, y1, x2, y2].map { |i| PdfInteger.new(i) })
        @x1, @y1, @x2, @y2 = x1, y1, x2, y2
      end
    end

    # defines Type1, TrueType, etc font
    class PdfFont <  PdfDictionaryObject
      def encoding=(encoding)
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
        dictionary['Widths'] = widths.reference_object unless widths.nil?
        dictionary['FontDescriptor'] = font_descriptor.reference_object unless font_descriptor.nil?
      end

      def self.standard_encoding?(encoding)
        PdfK::STANDARD_ENCODINGS.include?(encoding)
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
        dictionary['StemV'] = PdfInteger.new(stem_v) if stem_v
        dictionary['StemH'] = PdfInteger.new(stem_h) if stem_h
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

    class PdfTextAnnot < PdfAnnot
      def initialize(seq, gen, rect, contents)
        super(seq, gen, 'Text', rect)
        dictionary['Contents'] = PdfString.new(contents)
      end

      def open=(open)
        dictionary['Open'] = PdfBoolean.new(open)
      end
    end

    class PdfLinkAnnot < PdfAnnot
      def initialize(seq, gen, rect)
        super(seq, gen, 'Link', rect)
      end

      def dest=(dest)
        value = if dist.is_a?(String)
          PdfName.new(dest)
        elsif dist.is_a?(Array)
          PdfArray.new(dest)
        else
          dest
        end
        dictionary['Dest'] = value
      end

      def action=(action)
        dictionary['A'] = action.is_a?(Hash) ? PdfDictionary.new(action) : action
      end
    end

    class PdfMovieAnnot < PdfAnnot
      def initialize(seq, gen, rect, movie)
        # movie: Hash
        super(seq, gen, 'Movie', rect)
        dictionary['Movie'] = PdfDictionary.new(movie)
      end

      def activation=(activation)
        # activation: Hash or boolean
        dictionary['A'] = activation.is_a?(Hash) ? PdfDictionary.new(activation) : PdfBoolean.new(activation)
      end
    end

    class PdfSoundAnnot <  PdfAnnot
      def initialize(seq, gen, rect, sound)
        # sound: PdfStream
        super(seq, gen, 'Sound', rect)
        dictionary['Sound'] = sound
      end
    end

    class PdfURIAction < PdfDictionary
      def initialize(uri)
      end
    end

    class PdfAnnotBorder < PdfDictionary
      def initialize(sub_type)
      end
    end

    # defines resources used by a page or collection of pages
    class PdfResources < PdfDictionaryObject
      def proc_set=(pdf_object)
        # pdf_object: PdfArray or IndirectObjectRef
        dictionary['ProcSet'] = pdf_object
      end

      def fonts
        @fonts ||= PdfDictionary.new
        dictionary['Font'] ||= @fonts
      end

      def x_objects
        @x_objects ||= PdfDictionary.new
        dictionary['XObject'] ||= @x_objects
      end
    end
  
    # common elements between a page and a collection of pages
    class PdfPageBase < PdfDictionaryObject
      def initialize(seq, gen, parent=nil)
        # parent: IndirectObjectRef
        super(seq, gen)
        dictionary['Parent'] = parent.reference_object unless parent.nil?
      end

      def media_box=(media_box)
        # media_box: Rectangle
        dictionary['MediaBox'] = media_box
      end

      def resources=(resources)
        # resources: IndirectObjectRef
        dictionary['Resources'] = resources.reference_object
      end

      def crop_box=(crop_box)
        # crop_box: Rectangle
        dictionary['CropBox'] = crop_box
      end

      def rotate=(rotate)
        # rotate: integer
        dictionary['Rotate'] = PdfInteger.new(rotate)
      end

      def duration=(duration)
        # duration: integer or float
        dictionary['Dur'] = PdfNumber.new(duration)
      end

      def hidden=(hidden)
        # hidden: boolean
        dictionary['Hid'] = PdfBoolean.new(hidden)
      end

      def transition=(transition)
        # transition: hash
        dictionary['Trans'] = PdfDictionary.new(transition)
      end

      def additional_actions=(additional_actions)
        # additional_actions: hash
        dictionary['AA'] = PdfDictionary.new(additional_actions)
      end
    end

    # one page of a PDF document, not counting resources defined in a parent
    class PdfPage < PdfPageBase
      def initialize(seq, gen, parent)
        super(seq, gen, parent)
        dictionary['Type'] = PdfName.new('Page')
      end

      def body
        if contents.size > 1
          dictionary['Contents'] = PdfArray.new(contents.map { |stream| stream.reference_object })
        elsif contents.size == 1
          dictionary['Contents'] = contents.first.reference_object
        end
        dictionary['Length'] = PdfInteger.new(contents.inject(0) { |length, stream| length + stream.length })
        super
      end

      # PdfStream's
      def contents
        @contents ||= []
      end

      def thumb=(thumb)
        # thumb: stream
        dictionary['Thumb'] = thumb.reference_object
      end

      def annots=(annots)
        # annots: array of dictionary objects
        (@annots ||= []).concat(annots)
        dictionary['Annots'] = PdfArray.new(@annots.map { |annot| annot.reference_object })
      end

      def beads=(beads)
        # beads: array of dictionary objects
        dictionary['B'] = PdfArray.new(beads.map { |bead| bead.reference_object })
      end
    end
  
    # collection of pages
    class PdfPages < PdfPageBase
      attr_reader :kids # array of refs to PdfPageBase

      def initialize(seq, gen, parent=nil)
        super(seq, gen, parent)
        @kids = []
        dictionary['Type'] = PdfName.new('Pages')
      end

      def to_s
        dictionary['Count'] = PdfInteger.new(@kids.size)
        dictionary['Kids'] = PdfArray.new(@kids.map { |page| page.reference_object })
        super
      end
    end

    class PdfOutlines < PdfDictionaryObject
      def initialize(seq, gen)
        super(seq, gen)
        dictionary['Type'] = PdfName.new('Outlines')
      end

      def to_s
        dictionary['Count'] = PdfInteger.new(0)
        super
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
          @pages = pages
          dictionary['Pages'] = pages.reference_object
        end
        if outlines
          @outlines = outlines
          dictionary['Outlines'] = outlines.reference_object
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

    # root of object tree representing a PDF document
    class PdfFile
      attr_reader :header, :body, :trailer

      def initialize
        @header = Header.new
        @body = Body.new
        @trailer = Trailer.new
      end

      def to_s
        xref_table = XRefTable.new
        xref_sub_section = XRefSubSection.new
        xref_table << xref_sub_section

        s = @header.to_s
        @body.write_and_xref(s, xref_sub_section)
        @trailer.xref_table_start = s.length
        @trailer.xref_table_size = xref_sub_section.size
        s << xref_table.to_s
        s << @trailer.to_s
      end
    end
  end
end
