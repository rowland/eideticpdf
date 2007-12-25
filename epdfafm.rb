#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-12-18.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

require 'epdfk'
require 'epdfo'

module EideticPDF
  module AFM
    FontMetrics = Struct.new(:needs_descriptor, :widths, :ascent, :descent, :flags, :b_box, :missing_width,
      :stem_v, :stem_h, :italic_angle, :cap_height, :x_height, :leading, :max_width, :avg_width, :differences)
    # AfmChar = Struct.new(:code, :name, :w0x, :w1x, :w0y, :w1y, :w0, :w1, :vv, :b, :l)
    AfmChar = Struct.new(:code, :name, :width)
    FontPath = [File.join(File.dirname(__FILE__), 'fonts')]

    class AdobeFontMetrics
      FixedPitch  = 0x01
      Serif       = 0x02
      Symbolic    = 0x04
      Script      = 0x08
      NonSymbolic = 0x20
      Italic      = 0x40

      attr_reader :font_name, :full_name, :family_name, :weight, :italic_angle, :is_fixed_pitch
      attr_reader :font_b_box, :underline_position, :underline_thickness
      attr_reader :version, :notice
      attr_reader :character_set, :encoding_scheme
      attr_reader :cap_height, :x_height, :ascender, :descender, :std_h_w, :std_v_w
      attr_reader :chars_by_name, :chars_by_code

      def initialize(lines)
        lines.each do |line|
          if @char_metrics_started
            load_char_metrics(line)
          else
            load_line(line)
          end
        end
      end

      def flags
        @flags = 0
        @flags |= FixedPitch if @is_fixed_pitch
        @flags |= Serif if @family_name =~ /Times/
        if ['Symbol','ZapfDingbats'].include?(@family_name)
          @flags |= Symbolic
        else
          @flags |= NonSymbolic
        end
        # TODO: detect Script
        @flags |= Italic if @italic_angle != 0
        @flags
      end

      def self.load(file)
        self.new(IO.readlines(file))
      end

      def self.find_font(family_name, weight, italic)
        afm = afm_cache.find do |afm|
          (family_name.casecmp(afm.family_name) == 0) and 
          (weight.casecmp(afm.weight) == 0) and
          (italic ? afm.italic_angle != 0 : afm.italic_angle == 0)
        end
        afm
      end

      def self.afm_cache(reload=false)
        return $afm_cache unless $afm_cache.nil? or reload
        $afm_cache = []
        FontPath.each do |path|
          Dir[File.join(path, '*.afm')].each do |file|
            $afm_cache << AdobeFontMetrics.load(file)
          end
        end
        $afm_cache
      end

    protected
      def load_line(line)
        case line
        when /FontName\s+(.*)$/
          @font_name = $1.chomp
        when /FullName\s+(.*)/
          @full_name = $1.chomp
        when /FamilyName\s+(\w+)/
          @family_name = $1
        when /Weight\s+(\w+)/
          @weight = $1
        when /ItalicAngle\s+(-?\d+)/
          @italic_angle = $1.to_f
        when /IsFixedPitch\s+(\w+)/
          @is_fixed_pitch = ($1 == 'true')
        when /CharacterSet\s+(\w+)/
          @character_set = $1
        when /FontBBox((\s+-?\d+){4})/
          @font_b_box = $1.split.map { |d| d.to_i }
        when /UnderlinePosition\s+(-?\d+)/
          @underline_position = $1.to_i
        when /UnderlineThickness\s+(\d+)/
          @underline_thickness = $1.to_i
        when /Version\s+(.*)/
          @version = $1.chomp
        when /Notice\s+(.*)/
          @notice = $1.chomp
        when /EncodingScheme\s+(\w+)/
          @encoding_scheme = $1
        when /CapHeight\s+(\d+)/
          @cap_height = $1.to_i
        when /XHeight\s+(\d+)/
          @x_height = $1.to_i
        when /Ascender\s+(\d+)/
          @ascender = $1.to_i
        when /Descender\s+(-?\d+)/
          @descender = $1.to_i
        when /StdHW\s+(\d+)/
          @std_h_w = $1.to_i
        when /StdVW\s+(\d+)/
          @std_v_w = $1.to_i
        when /StartCharMetrics/
          @chars_by_name = {}
          @chars_by_code = []
          @char_metrics_started = true
        end
      end

      def load_char_metrics(line)
        if line =~ /EndCharMetrics/
          @char_metrics_started = false
        else
          ch = AfmChar.new
          line.split(';').map { |kv| kv.strip }.each do |kv|
            k, v = kv.split
            case k
            when 'C': ch.code = v.to_i
            when 'CH': ch.code = v[1..-2].to_i(16)
            when 'WX', 'W0X': ch.width = v.to_i
            when 'N': ch.name = v
            end
          end
          raise Exception.new("bad: #{kv}") if ch.name.nil? or ch.code.nil?
          @chars_by_name[ch.name] = ch
          # cbc1 = @chars_by_code.compact.size
          @chars_by_code[ch.code] = ch if ch.code > 0
          # cbc2 = @chars_by_code.compact.size
          # raise Exception.new("trouble: #{line}") if cbc2 != cbc1 + 1 and ch.code > 0
        end
      end
    end

    def font_metrics(family, options={})
      style = Array(options[:style] || '').map { |style| style.capitalize }
      bold, italic = style.include?('Bold'), style.include?('Italic')
      weight = bold ? 'Bold' : options[:weight] || ((family =~ /Times/i && !italic) ? 'Roman' : 'Medium')
      afm = AdobeFontMetrics.find_font(family, weight, italic)
      raise Exception.new("Unknown font %s-%s%s." % [family, weight, italic ? 'Italic' : '']) if afm.nil?
      if afm.encoding_scheme == 'FontSpecific'
        encoding = nil
        needs_descriptor = false
      else
        encoding = options[:encoding] || 'WinAnsiEncoding'
        needs_descriptor = !PdfK::STANDARD_ENCODINGS.include?(encoding)
      end
      if needs_descriptor
        differences = glyph_differences_for_encodings('WinAnsiEncoding', encoding)
      else
        differences = nil
      end
      if encoding.nil? or encoding == 'StandardEncoding'
        widths = afm.chars_by_code.inject([]) do |widths, ch|
          next widths if ch.nil?
          widths[ch.code] = ch.width
          widths
        end
      else
        widths = widths_for_encoding(encoding, afm.chars_by_name)
      end
      missing_width = 0 # for CJK charsets only?
      leading = 0 # for CJK charsets only?
      cwidths = widths.compact.extend(Statistics)
      fm = FontMetrics.new(needs_descriptor, widths, afm.ascender, afm.descender, afm.flags, afm.font_b_box, missing_width,
        afm.std_v_w, afm.std_h_w, afm.italic_angle, afm.cap_height, afm.x_height, leading, cwidths.max, cwidths.avg, differences)
      fm
    end

    def codepoints_for_encoding(encoding)
      require 'iconv'
      encoding = 'CP1252' if encoding == 'WinAnsiEncoding'
      Iconv.open("UCS-2BE//IGNORE", encoding) do |ic|
        (0..255).map { |c| ic.iconv(c.chr) }.map { |s| s.unpack('n') }.map { |a| a.first }
      end
    end

    def glyphs_for_codepoints(codepoints)
      codepoints.map { |codepoint| PdfK::glyph_name(codepoint) }
    end

    def glyphs_for_encoding(encoding)
      glyphs_for_codepoints(codepoints_for_encoding(encoding))
    end

    def widths_for_glyphs(glyphs, chars_by_name)
      glyphs.map { |glyph| chars_by_name[glyph].width }
    end

    def widths_for_encoding(encoding, chars_by_name)
      widths_for_glyphs(glyphs_for_encoding(encoding), chars_by_name)
    end
    
    def glyph_differences_for_encodings(encoding1, encoding2)
      glyphs1, glyphs2 = glyphs_for_encoding(encoding1), glyphs_for_encoding(encoding2)
      result = []
      same = true
      1.upto(255) do |i|
        if same
          if glyphs1[i] != glyphs2[i]
            same = false
            result << PdfObjects::PdfInteger.new(i)
            result << PdfObjects::PdfName.new(glyphs2[i])
          end
        else
          if glyphs1[i] == glyphs2[i]
            same = true
          else
            result << PdfObjects::PdfName.new(glyphs2[i])
          end
        end
      end
      PdfObjects::PdfArray.new(result)
    end

    module Statistics
      def sum
        self.inject(0) { |total, obj| total + obj }
      end

      def avg
        self.sum / self.size
      end
    end
  end
end
