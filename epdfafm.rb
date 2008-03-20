#!/usr/bin/env ruby
# encoding: ASCII-8BIT
#
#  Created by Brent Rowland on 2007-12-18.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

require 'epdfk'
require 'epdfo'
require 'epdfs'

module EideticPDF
  module AFM # :nodoc: all
    # AfmChar = Struct.new(:code, :name, :w0x, :w1x, :w0y, :w1y, :w0, :w1, :vv, :b, :l)
    AfmChar = Struct.new(:code, :name, :width)
    FontPath = [File.join(File.dirname(__FILE__), 'fonts')]

    class Codepoints
      def self.for_encoding(encoding)
        require 'iconv'
        encoding = 'CP1252' if encoding == 'WinAnsiEncoding'
        @@codepoints_by_encoding ||= {}
        @@codepoints_by_encoding[encoding] ||= Iconv.open("UCS-2BE//IGNORE", encoding) do |ic|
          (0..255).map { |c| ic.iconv(c.chr) }.map { |s| s.unpack('n') }.map { |a| a.first }
        end
      end
    end

    class Glyphs
      def self.for_codepoints(codepoints)
        codepoints.map { |codepoint| PdfK::glyph_name(codepoint) }
      end

      def self.for_encoding(encoding)
        @@glyphs_by_encoding ||= {}
        @@glyphs_by_encoding[encoding] ||= for_codepoints(Codepoints.for_encoding(encoding))
      end

      def self.widths_for_glyphs(glyphs, chars_by_name)
        glyphs.map { |glyph| (ch = chars_by_name[glyph]) ? ch.width : 0 }
      end

      def self.widths_for_encoding(encoding, chars_by_name)
        widths_for_glyphs(for_encoding(encoding), chars_by_name)
      end

      def self.differences_for_encodings(encoding1, encoding2)
        @@glyph_differences_for_encodings ||= {}
        key = "#{encoding1}-#{encoding2}"
        result = @@glyph_differences_for_encodings[key]
        if result.nil?
          glyphs1, glyphs2 = for_encoding(encoding1), for_encoding(encoding2)
          diffs = []
          same = true
          1.upto(255) do |i|
            if same
              if (glyphs1[i] != glyphs2[i]) and !glyphs2[i].nil?
                same = false
                diffs << PdfObjects::PdfInteger.new(i)
                diffs << PdfObjects::PdfName.new(glyphs2[i])
              end
            else
              if glyphs1[i] == glyphs2[i]
                same = true
              else
                diffs << PdfObjects::PdfName.new(glyphs2[i])
              end
            end
          end
          result = @@glyph_differences_for_encodings[key] = PdfObjects::PdfArray.new(diffs)
        end
        result
      end
    end

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
      attr_reader :font_b_box, :underline_position, :underline_thickness, :missing_width, :leading
      attr_reader :version, :notice
      attr_reader :character_set, :encoding_scheme
      attr_reader :cap_height, :x_height, :ascender, :descender, :std_h_w, :std_v_w, :serif
      attr_reader :chars_by_name, :chars_by_code

      def load_afm(lines)
        lines.each do |line|
          break if @kern_data_started
          if @char_metrics_started
            load_char_metrics(line)
          else
            load_line(line)
          end
        end
        # symbolic fonts don't specify ascender and descender, so default to reasonable numbers.
        @ascender ||= 750
        @descender ||= -188
        @missing_width = 0 # for CJK charsets only?
        @leading = 0 # for CJK charsets only?
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

      def needs_descriptor(encoding)
        if encoding_scheme == 'FontSpecific'
          false
        else
          !(0...14).include?(PdfK::font_index(font_name)) || !PdfK::STANDARD_ENCODINGS.include?(encoding)
        end
      end

      def differences(encoding)
        if (encoding != :unicode) and needs_descriptor(encoding)
          Glyphs.differences_for_encodings('WinAnsiEncoding', encoding)
        else
          false
        end
      end

      def widths(encoding)
        result = (@widths ||= {})[encoding]
        if result.nil?
          if encoding == :unicode
            result = Hash.new(missing_width)
            chars_by_name.each do |name, ch|
              results[PdfK::CODEPOINTS[name]] = ch.width
            end
          elsif encoding.nil? or encoding == 'StandardEncoding'
            result = Array.new(256, 0)
            chars_by_code.each do |ch|
              result[ch.code] = ch.width unless ch.nil?
            end
          else
            result = Glyphs.widths_for_encoding(encoding, chars_by_name)
          end
          @widths[encoding] = result
        end
        result
      end

      def self.load(afm_file)
        result = self.new
        result.load_afm(IO.readlines(afm_file))
        inf_file = afm_file.sub(/\.afm$/, '.inf')
        result.load_inf(IO.readlines(inf_file)) if File.exist?(inf_file)
        result
      end

      def self.find_font(full_name)
        if full_name.is_a?(Regexp)
          afm_cache.find { |afm| full_name =~ afm.font_name }
        else
          afm_cache.find { |afm| full_name.casecmp(afm.font_name) == 0 }
        end
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
        when /^FontName\s+(.*)$/
          @font_name = $1.chomp
        when /^FullName\s+(.*)/
          @full_name = $1.chomp
        when /^FamilyName\s+(.*)/
          @family_name = $1.chomp
        when /^Weight\s+(\w+)/
          @weight = $1
        when /^ItalicAngle\s+(-?\d+(\.\d+)?)/
          @italic_angle = $1.to_f
        when /^IsFixedPitch\s+(\w+)/
          @is_fixed_pitch = ($1 == 'true')
        when /^CharacterSet\s+(\w+)/
          @character_set = $1
        when /^FontBBox((\s+-?\d+){4})/
          @font_b_box = $1.split.map { |d| d.to_i }
        when /^UnderlinePosition\s+(-?\d+)/
          @underline_position = $1.to_i
        when /^UnderlineThickness\s+(\d+)/
          @underline_thickness = $1.to_i
        when /^Version\s+(.*)/
          @version = $1.chomp
        when /^Notice\s+(.*)/
          @notice = $1.chomp
        when /^EncodingScheme\s+(\w+)/
          @encoding_scheme = $1
        when /^CapHeight\s+(\d+)/
          @cap_height = $1.to_i
        when /^XHeight\s+(\d+)/
          @x_height = $1.to_i
        when /^Ascender\s+(\d+)/
          @ascender = $1.to_i
        when /^Descender\s+(-?\d+)/
          @descender = $1.to_i
        when /^StdHW\s+(\d+)/
          @std_h_w = $1.to_i
        when /^StdVW\s+(\d+)/
          @std_v_w = $1.to_i
        when /^StartCharMetrics/
          @chars_by_name = {}
          @chars_by_code = []
          @char_metrics_started = true
        when /^Serif\s+(\w+)/
          @serif = ($1 == 'true')
        when /^StartKernData/
          @kern_data_started = true
        end
      end

      def load_char_metrics(line)
        if line =~ /^EndCharMetrics/
          @char_metrics_started = false
        else
          ch = AfmChar.new
          if line =~ /^C\s+(-?\d+)\s*;\s*WX\s+(\d+)\s*;\s*N\s+(\w+)/
            ch.code = $1.to_i
            ch.width = $2.to_i
            ch.name = $3
          else
            line.split(';').map { |kv| kv.strip }.each do |kv|
              k, v = kv.split
              case k
              when 'C'         then ch.code = v.to_i
              when 'CH'        then ch.code = v[1..-2].to_i(16)
              when 'WX', 'W0X' then ch.width = v.to_i
              when 'N'         then ch.name = v
              end
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
    def find_font(family, weight='', style='')
      italic = (style =~ /Italic|Oblique/i) ? '(Italic|Obl(ique)?)' : ''
      weight_style = "#{weight}#{italic}"
      re_s = '^' + family
      if weight_style.empty?
        re_s << '(-Roman)?'
      else
        re_s << '-' << weight_style
      end
      re_s << '$'
      re = Regexp.new(re_s, Regexp::IGNORECASE)
      afm = AdobeFontMetrics.find_font(re)
    end

    def font_metrics(name, options={})
      afm = find_font(name, options[:weight], options[:style])
      raise Exception.new("Unknown font %s." % name) if afm.nil?
      encoding = (afm.encoding_scheme == 'FontSpecific') ? nil : options[:encoding] || 'WinAnsiEncoding'
      needs_descriptor = afm.needs_descriptor(encoding)
      differences = afm.differences(encoding)
      widths = afm.widths(encoding)
      cwidths = widths.compact.extend(Statistics)
      fm = PdfK::FontMetrics.new(needs_descriptor, widths, afm.ascender, afm.descender, afm.flags, afm.font_b_box, afm.missing_width,
        afm.std_v_w, afm.std_h_w, afm.italic_angle, afm.cap_height, afm.x_height, afm.leading, cwidths.max, cwidths.mean.round,
        afm.underline_position, afm.underline_thickness, differences)
      fm
    end

    def font_weights(family_name)
      AdobeFontMetrics.find_fonts(:family_name => family_name).map { |afm| afm.weight }.sort.uniq
    end

    def font_names(reload=false)
      AdobeFontMetrics.afm_cache(reload).map { |afm| afm.font_name }
    end
  end
end
