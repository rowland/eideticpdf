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
      AllCap      = 0x10000
      SmallCap    = 0x20000
      ForceBold   = 0x40000

      attr_reader :font_name, :full_name, :family_name, :weight, :italic_angle, :is_fixed_pitch
      attr_reader :font_b_box, :underline_position, :underline_thickness
      attr_reader :version, :notice
      attr_reader :character_set, :encoding_scheme
      attr_reader :cap_height, :x_height, :ascender, :descender, :std_h_w, :std_v_w, :serif
      attr_reader :chars_by_name, :chars_by_code

      def load_afm(lines)
        lines.each do |line|
          if @char_metrics_started
            load_char_metrics(line)
          else
            load_line(line)
          end
        end
        # symbolic fonts don't specify ascender and descender, so borrow them from FontBBox
        @ascender ||= font_b_box[3]
        @descender ||= font_b_box[1]
        self
      end

      def load_inf(lines)
        lines.grep(/^Serif/).each do |line|
          load_line(line)
        end
        self
      end          

      def flags
        @flags = 0
        @flags |= FixedPitch if @is_fixed_pitch
        @flags |= Serif if @serif
        if ['Symbol','ZapfDingbats'].include?(@family_name)
          @flags |= Symbolic
        else
          @flags |= NonSymbolic
        end
        # TODO: detect Script
        @flags |= Italic if @italic_angle != 0
        @flags |= ForceBold if @weight =~ /Bold|Demi/i
        @flags
      end

      def italic
        @italic_angle != 0
      end

      def self.load(afm_file)
        result = self.new
        result.load_afm(IO.readlines(afm_file))
        inf_file = afm_file.sub(/\.afm$/, '.inf')
        result.load_inf(IO.readlines(inf_file)) if File.exist?(inf_file)
        result
      end

      def self.find_font(full_name)
        afm_cache.find { |afm| full_name.casecmp(afm.font_name) == 0 }
      end

      def self.find_fonts(options)
        afm_cache.select do |afm|
          options.all? do |key, value|
            if value.respond_to?(:to_str)
              value.casecmp(afm.send(key)) == 0
            elsif value.is_a?(Regexp)
              value =~ afm.send(key)
            else
              value == afm.send(key)
            end
          end
        end
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
        when /FamilyName\s+(.*)/
          @family_name = $1.chomp
        when /Weight\s+(\w+)/
          @weight = $1
        when /ItalicAngle\s+(-?\d+(\.\d+)?)/
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
        when /Serif\s+(\w+)/
          @serif = ($1 == 'true')
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

  module_function
    def font_metrics(name, options={})
      unless options[:weight].nil? and options[:italic].nil?
        weight = options[:weight] || /Medium|Roman/
        italic = options[:italic] || false
        afm = AdobeFontMetrics.find_fonts(:family_name => name, :weight => weight, :italic => italic).first
      end
      afm = AdobeFontMetrics.find_font(name) if afm.nil?
      raise Exception.new("Unknown font %s." % name) if afm.nil?
      if afm.encoding_scheme == 'FontSpecific'
        encoding = nil
        needs_descriptor = false
      else
        encoding = options[:encoding] || 'WinAnsiEncoding'
        needs_descriptor = !(0...14).include?(PdfK::font_index(afm.font_name)) || !PdfK::STANDARD_ENCODINGS.include?(encoding)
        # $stdout.puts "needs descriptor: #{needs_descriptor}"
      end
      if needs_descriptor
        differences = glyph_differences_for_encodings('WinAnsiEncoding', encoding)
      else
        differences = nil
      end
      if encoding.nil? or encoding == 'StandardEncoding'
        widths = Array.new(256, 0)
        afm.chars_by_code.each do |ch|
          widths[ch.code] = ch.width unless ch.nil?
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

    def font_weights(family_name)
      AdobeFontMetrics.find_fonts(:family_name => family_name).map { |afm| afm.weight }.sort.uniq
    end

    def font_names(reload=false)
      AdobeFontMetrics.afm_cache(reload).map { |afm| afm.font_name }
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
      glyphs.map { |glyph| (ch = chars_by_name[glyph]) ? ch.width : 0 }
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
          if (glyphs1[i] != glyphs2[i]) and !glyphs2[i].nil?
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
