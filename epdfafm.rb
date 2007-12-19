#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-12-18.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

module EideticPDF
  module AFM
    # AfmChar = Struct.new(:code, :name, :w0x, :w1x, :w0y, :w1y, :w0, :w1, :vv, :b, :l)
    AfmChar = Struct.new(:code, :name, :width)

    class AdobeFontMetrics
      attr_reader :font_name, :full_name, :family_name, :weight, :italic_angle, :is_fixed_pitch, :character_set
      attr_reader :font_b_box, :underline_position, :underline_thickness, :version, :notice, :encoding_scheme
      attr_reader :cap_height, :x_height, :ascender, :descender, :std_h_w, :std_v_w
      attr_reader :char_metrics

      def load(file)
        IO.foreach(file) do |line|
          if @char_metrics_started
            load_char_metrics(line)
          else
            load_line(line)
          end
        end
      end

      def self.load(file)
        result = self.new
        result.load(file)
        result
      end

    protected
      def load_line(line)
        case line
        when /FontName\s+(.*)/
          @font_name = $1
        when /FullName\s+(.*)/
          @full_name = $1
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
        when /UnderlinePosition\w+(-?\d+)/
          @underline_position = $1.to_i
        when /UnderlineThickness\s+(\d+)/
          @underline_thickness = $1.to_i
        when /Version\s+(.*)/
          @version = $1
        when /Notice\s+(.*)/
          @notice = $1
        when /EncodingScheme\s+(\w+)/
          @encoding_scheme = $1
        when /CapHeight\s+(\d+)/
          @cap_height = $1.to_i
        when /XHeight\s+(\d+)/
          @x_height = $1.to_i
        when /Ascender\s+(\d+)/
          @ascender = $1.to_i
        when /Descender\s+(\d+)/
          @descender = $1.to_i
        when /StdHW\s+(\d+)/
          @std_h_w = $1.to_i
        when /StdVW\s+(\d+)/
          @std_v_w = $1.to_i
        when /StartCharMetrics/
          @char_metrics = {}
          @char_metrics_started = true
        end
      end

      def load_char_metrics(line)
        if line =~  /EndCharMetrics/
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
            when /EndCharMetrics/: @char_metrics_started = false
            end
          end
          @char_metrics[ch.name] = ch
        end
      end
    end
  end
end
