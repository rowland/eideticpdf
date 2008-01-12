#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-07-13.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

require 'epdfo'
require 'epdfk'
require 'epdft'
require 'epdfafm'
require 'epdftt'

module EideticPDF
  Font = Struct.new(:name, :size, :style, :color, :encoding, :sub_type, :widths, :ascent, :descent, :height,
    :underline_position, :underline_thickness)
  Location = Struct.new(:x, :y)
  Signs = Struct.new(:x, :y)

  SIGNS = [ Signs.new(1, -1), Signs.new(-1, -1), Signs.new(-1, 1), Signs.new(1, 1) ]
  UNIT_CONVERSION = { :pt => 1, :in => 72, :cm => 28.35 }
  LINE_PATTERNS = { :solid => [], :dotted => [1, 2], :dashed => [4, 2] }
  IDENTITY_MATRIX = [1, 0, 0, 1, 0, 0].freeze

  class PropertyStack
    def initialize(obj, prop, &block)
      @obj, @prop, @condition = obj, prop, block
      @stack = []
    end

    def push(value)
      @stack.push @obj.send(@prop)
      @obj.send(@prop, value) if @condition.call(value)
    end

    def pop
      value = @stack.pop
      @obj.send(@prop, value) if @condition.call(value)
    end
  end

  class ColorStack
    def initialize(obj, prop)
      @obj, @prop = obj, prop
      @stack = []
    end

    def push(color)
      @stack.push @obj.send(@prop)
      @obj.send(@prop, color) if color.respond_to?(:to_int) or color.respond_to?(:to_str)
    end

    def pop
      color = @stack.pop
      @obj.send(@prop, color) if color.respond_to?(:to_int) or color.respond_to?(:to_str)
    end
  end

  class PageStyle
    attr_reader :page_size, :crop_size, :orientation, :landscape, :rotate

    PORTRAIT = 0
    LANDSCAPE = 270

    def initialize(options={})
      page_size = options[:page_size] || :letter
      crop_size = options[:crop_size] || page_size
      @orientation = options[:orientation] || :portrait
      @page_size = make_size_rectangle(page_size, @orientation)
      @crop_size = make_size_rectangle(crop_size, @orientation)
      @landscape = (@orientation == :landscape)
      @rotate = ROTATIONS[options[:rotate] || :portrait]
    end

    SIZES = {
      :letter => [612, 792].freeze,
      :legal => [612, 1008].freeze,
      :A4 => [595, 842].freeze,
      :B5 => [499, 708].freeze,
      :C5 => [459, 649].freeze
    }
    ROTATIONS = { :portrait => PORTRAIT, :landscape => LANDSCAPE }.freeze

  protected
    def make_size_rectangle(size, orientation)
      w, h = SIZES[size]
      w, h = h, w if orientation == :landscape
      PdfObjects::Rectangle.new(0, 0, w, h)
    end
  end

  class BaseWriter
    def f(value, prec=2)
      sprintf("%.*f", prec, value).sub(',','.')
    end

    def g(value, prec=4)
      # prec must be >= 1 or gsub will strip significant trailing 0's.
      sprintf("%.*f", prec, value).sub(',','.').gsub(/\.?0*$/,'')
    end
  end

  class MiscWriter < BaseWriter
    def initialize(stream)
      @stream = stream
    end

    def set_gray_fill(gray)
      @stream << "%s g\n" % g(gray)
    end

    def set_gray_stroke(gray)
      @stream << "%s G\n" % g(gray)
    end

    def set_cmyk_color_fill(c, m, y, k)
      @stream << "%s %s %s %s k\n" % [g(c), g(m), g(y), g(k)]
    end

    def set_cmyk_color_stroke(c, m, y, k)
      @stream << "%s %s %s %s K\n" % [g(c), g(m), g(y), g(k)]
    end

    def set_rgb_color_fill(red, green, blue)
      @stream << "%s %s %s rg\n" % [g(red), g(green), g(blue)]
    end

    def set_rgb_color_stroke(red, green, blue)
      @stream << "%s %s %s RG\n" % [g(red), g(green), g(blue)]
    end

    def set_color_space_fill(name)
      @stream << "/#{name} cs\n"
    end

    def set_color_space_stroke(name)
      @stream << "/#{name} CS\n"
    end

    def set_color_fill(colors)
      @stream << "%s sc\n" % colors.map { |c| g(c) }.join(' ')
    end

    def set_color_stroke(colors)
      @stream << "%s SC\n" % colors.map { |c| g(c) }.join(' ')
    end

    # xxx scn, SCN: patterns and separations
    def set_color_rendering_intent(intent)
      @stream << "/#{intent} ri\n"
    end

    def x_object(name)
      @stream << "/#{name} Do\n"
    end
  end

  class GraphWriter < BaseWriter
    def initialize(stream)
      @stream = stream
    end

    def save_graphics_state
      @stream << "q\n"
    end

    def restore_graphics_state
      @stream << "Q\n"
    end

    def concat_matrix(a, b, c, d, x, y)
      @stream << "%s %s %s %s %s %s cm\n" % [g(a), g(b), g(c), g(d), g(x), g(y)]
    end

    def set_flatness(flatness)
      @stream << "%d i\n" % flatness
    end

    def set_line_cap_style(line_cap_style)
      @stream << "%d J\n" % line_cap_style
    end

    def set_line_dash_pattern(line_dash_pattern)
      @stream << "%s d\n" % line_dash_pattern
    end

    def set_line_join_style(line_join_style)
      @stream << "%d j\n" % line_join_style
    end

    def set_line_width(line_width)
      @stream << "%s w\n" % g(line_width)
    end

    def set_miter_limit(miter_limit)
      @stream << "%s M\n" % g(miter_limit)
    end

    def move_to(x, y)
      @stream << "%s %s m\n" % [g(x), g(y)]
    end

    def line_to(x, y)
      @stream << "%s %s l\n" % [g(x), g(y)]
    end

    def curve_to(x1, y1, x2, y2, x3, y3)
      @stream << "%s %s %s %s %s %s c\n" % [g(x1), g(y1), g(x2), g(y2), g(x3), g(y3)]
    end

    def rectangle(x, y, width, height)
      @stream << "%s %s %s %s re\n" % [g(x), g(y), g(width), g(height)]
    end

    def close_path
      @stream << "h\n"
    end

    def new_path
      @stream << "n\n"
    end

    def stroke
      @stream << "S\n"
    end

    def close_path_and_stroke
      @stream << "s\n"
    end

    def fill
      @stream << "f\n"
    end

    def eo_fill
      @stream << "f*\n"
    end

    def fill_and_stroke
      @stream << "B\n"
    end

    def close_path_fill_and_stroke
      @stream << "b\n"
    end

    def eo_fill_and_stroke
      @stream << "B*\n"
    end

    def close_path_eo_fill_and_stroke
      @stream << "b*\n"
    end

    # use nonzero winding number rule
    def clip
      @stream << "W\n"
    end

    # use even-odd rule
    def eo_clip
      @stream << "W*\n"
    end

    def make_line_dash_pattern(pattern, phase)
      "[%s] %d" % [pattern.join(' '), phase]
    end
  end  

  class TextWriter < BaseWriter
    def initialize(stream)
      @stream = stream
    end
    
    def open
      @stream << "BT\n"
    end
    
    def close
      @stream << "ET\n"
    end

    def set_char_spacing(char_space)
      @stream << "%s Tc\n" % g(char_space)
    end

    def set_word_spacing(word_space)
      @stream << "%s Tw\n" % g(word_space)
    end

    def set_horiz_scaling(scale)
      @stream << "%s Tz\n" % g(scale)
    end

    def set_leading(leading)
      @stream << "%s TL\n" % g(leading)
    end

    def set_font_and_size(font_name, size)
      @stream << "/%s %s Tf\n" % [font_name, g(size)]
    end

    def set_rendering_mode(render)
      @stream << "%d Tr\n" % render
    end

    def set_rise(rise)
      @stream << "%s Ts\n" % g(rise)
    end

    def move_by(tx, ty)
      @stream << "%s %s Td\n" % [g(tx), g(ty)]
    end

    def move_by_and_set_leading(tx, ty)
      @stream << "%s %s TD\n" % [g(tx), g(ty)]
    end

    def set_matrix(a, b, c, d, x, y)
      @stream << "%s %s %s %s %s %s Tm\n" % [g(a), g(b), g(c), g(d), g(x), g(y)]
    end

    def next_line
      @stream << "T*\n"
    end

    def show(s)
      @stream << "(%s) Tj\n" % PdfObjects::PdfString.escape(s)
    end

    def show_wide(ws)
      @stream << "(%s) Tj\n" % PdfObjects::PdfString.escape_wide(ws)
    end

    def next_line_show(s)
      @stream << "(%s) '" % PdfObjects::PdfString.escape(s)
    end

    def set_spacing_next_line_show(char_space, word_space, s)
      @stream << "%s %s (%s) \"\n" % [g(char_space), g(word_space), PdfObjects::PdfString.escape(s)]
    end

    def show_with_dispacements(elements)
      @stream << "%sTJ\n" % elements
    end
  end

  class PageWriter
  private
    def iconv_encoding(encoding)
      case encoding
      when 'WinAnsiEncoding': 'CP1252'
      else encoding
      end
    end

    def pdf_encoding(encoding)
      case encoding.upcase
      when 'CP1252': 'WinAnsiEncoding'
      else encoding
      end
    end

    def even?(n)
      n % 2 == 0
    end

    def odd?(n)
      n % 2 != 0
    end

    def radians_from_degrees(degrees)
      degrees * Math::PI / 180.0
    end

    def to_points(units, measurement)
      UNIT_CONVERSION[units] * measurement
    end

    def from_points(units, measurement)
      measurement.quo(UNIT_CONVERSION[units])
    end

    def make_loc(x, y)
      Location.new(x, y)
    end

    def translate(x, y)
      Location.new(x, page_height - y)
    end

    def translate_p(p)
      Location.new(p.x, page_height - p.y)
    end

    def convert_units(loc, from_units, to_units)
      Location.new(
        loc.x * UNIT_CONVERSION[from_units].quo(UNIT_CONVERSION[to_units]),
        loc.y * UNIT_CONVERSION[from_units].quo(UNIT_CONVERSION[to_units]))
    end

    def get_quadrant_bezier_points(quadrant, x, y, rx, ry=nil)
      ry = rx if ry.nil?
      a = 4.0 / 3.0 * (Math.sqrt(2) - 1.0)
      bp = []
      if odd?(quadrant) # quadrant is odd
        # (1,0)
        bp << make_loc(x + (rx * SIGNS[quadrant - 1].x), y)
        # (1,a)
        bp << make_loc(bp[0].x, y + (a * ry * SIGNS[quadrant - 1].y))
        # (a,1)
        bp << make_loc(x + (a * rx * SIGNS[quadrant - 1].x), y + (ry * SIGNS[quadrant - 1].y))
        # (0,1)
        bp << make_loc(x, bp[2].y)
      else # quadrant is even
        # (0,1)
        bp << make_loc(x, y + (ry * SIGNS[quadrant - 1].y))
        # (a,1)
        bp << make_loc(x + (a * rx * SIGNS[quadrant - 1].x), bp[0].y)
        # (1,a)
        bp << make_loc(x + (rx * SIGNS[quadrant - 1].x), y + (a * ry * SIGNS[quadrant - 1].y))
        # (1,0)
        bp << make_loc(bp[2].x, y)
      end
      bp
    end

    def rotate_xy_coordinate(x, y, angle)
      theta = radians_from_degrees(angle)
      r_cos = Math::cos(theta)
      r_sin = Math::sin(theta)
      x_rot = (r_cos * x) - (r_sin * y)
      y_rot = (r_sin * x) + (r_cos * y)
      [x_rot, y_rot]
    end

  	def rotate_point(loc, angle)
  		x, y = rotate_xy_coordinate(loc.x, loc.y, angle)
  		make_loc(x, y)
  	end

    def add_vector(point, angle, distance)
      theta = radians_from_degrees(angle)
      Location.new(point.x + Math::cos(theta) * distance, point.y + Math::sin(theta) * distance)
    end

  	def rotate_points(mid, points, angle)
      theta = radians_from_degrees(angle)
      r_cos = Math::cos(theta)
      r_sin = Math::sin(theta)
  	  points.map do |p|
  	    x, y = p.x - mid.x, p.y - mid.y
        x_rot = (r_cos * x) - (r_sin * y)
        y_rot = (r_sin * x) + (r_cos * y)
  	    make_loc(x_rot + mid.x, y_rot + mid.y)
      end
    end

    def calc_arc_small(r, mid_theta, half_angle, ccwcw)
      half_theta = radians_from_degrees(half_angle.abs)
      v_cos = Math::cos(half_theta)
      v_sin = Math::sin(half_theta)

      x0 = r * v_cos
      y0 = -ccwcw * r * v_sin
      x1 = r * (4.0 - v_cos) / 3.0
      x2 = x1
      y1 = r * ccwcw * (1.0 - v_cos) * (v_cos - 3.0) / (3.0 * v_sin)
      y2 = -y1
      x3 = r * v_cos
      y3 = ccwcw * r * v_sin

      x0, y0 = rotate_xy_coordinate(x0, y0, mid_theta)
      x1, y1 = rotate_xy_coordinate(x1, y1, mid_theta)
      x2, y2 = rotate_xy_coordinate(x2, y2, mid_theta)
      x3, y3 = rotate_xy_coordinate(x3, y3, mid_theta)

      [x0, y0, x1, y1, x2, y2, x3, y3]
    end

    def points_for_arc_small(x, y, r, mid_theta, half_angle, ccwcw)
      x0, y0, x1, y1, x2, y2, x3, y3 = calc_arc_small(r, mid_theta, half_angle, ccwcw)
      [make_loc(x+x0, y-y0), make_loc(x+x1, y-y1), make_loc(x+x2, y-y2), make_loc(x+x3, y-y3)]
    end

    def arc_small(x, y, r, mid_theta, half_angle, ccwcw, move_to0)
      x0, y0, x1, y1, x2, y2, x3, y3 = calc_arc_small(r, mid_theta, half_angle, ccwcw)
      line_to(x+x0, y-y0) unless move_to0
      curve(x+x0, y-y0, x+x1, y-y1, x+x2, y-y2, x+x3, y-y3)
    end

    def set_text_angle(angle, x, y)
      theta = radians_from_degrees(angle)
      v_cos = Math::cos(theta)
      v_sin = Math::sin(theta)
      @tw.set_matrix(v_cos, v_sin, -v_sin, v_cos, to_points(@units, x), to_points(@units, y))
      @text_angle = angle
    end

    def rgb_from_color(color)
      color = named_colors[color] || 0 if color.respond_to? :to_str
      color ||= 0
      b = color & 0xFF
      g = (color >> 8) & 0xFF
      r = (color >> 16) & 0xFF
      [r, g, b]
    end

    def color_from_rgb(r, g, b)
      (r << 16) | (g << 8) | b
    end
  protected
    def start_text
      raise Exception.new("Already in text.") if @in_text
      raise Exception.new("Not in page.") unless @doc.in_page
      end_graph if @in_graph
      @last_loc = Location.new(0, 0)
      @in_text = true
      @tw = TextWriter.new(@stream)
      @tw.open
      @tw
    end

    def end_text
      raise Exception.new("Not in text.") unless @in_text
      @tw.close
      @in_text = false
    end

    def start_graph
      raise Exception.new("Already in graph") if @in_graph
      end_text if @in_text
      @last_loc = Location.new(0, 0)
      @in_graph = true
      @gw = GraphWriter.new(@stream)
    end

    def end_path
      gw.stroke if @auto_path
      @in_path = false
    end

    def end_graph
      raise Exception.new("Not in graph") unless @in_graph
      end_path if @in_path
      @gw = nil
      @in_graph = false
    end

    def start_misc
      raise Exception.new("Already in misc") if @in_misc
      @in_misc = true
      @mw = MiscWriter.new(@stream)
    end

    def end_misc
      raise Exception.new("Not in misc") unless @in_misc
      @mw = nil
      @in_misc = false
    end

    def tw
      @tw ||= start_text
    end

    def gw
      @gw ||= start_graph
    end

    def mw
      @mw ||= start_misc
    end

    def end_margins
      end_path if @in_path
      gw.restore_graphics_state
    end

    def end_sub_page
      end_path if @in_path
      gw.restore_graphics_state
    end

    def sub_orientation(pages_across, pages_down)
      @page_width / pages_across > @page_height / pages_down ? :landscape : :portrait
    end

    # font methods
    def set_default_font
      font(@default_font[:name], @default_font[:size], @default_font)
    end

    def check_set_font
      set_default_font if @font.nil?
      if (@last_page_font != @page_font) or (@last_font != @font)
        @tw.set_font_and_size(@page_font, @font.size)
        check_set_v_text_align(true)
        @last_page_font = @page_font
        @last_font = @font
      end
    end

    def check_set_v_text_align(force=false)
      if force or @last_v_text_align != @v_text_align
        @v_text_align_pts = case @v_text_align
        when :above  : -@font.height * 0.001 * @font.size
        when :top    : -@font.ascent * 0.001 * @font.size
        when :middle : -@font.ascent * 0.001 * @font.size / 2.0
        when :below  : -@font.descent * 0.001 * @font.size
        else 0.0 # :base
        end
        @tw.set_rise(@v_text_align_pts)
        @last_v_text_align = @v_text_align
      end
    end
    
    def check_set_spacing
      unless @word_spacing == @last_word_spacing
        tw.set_word_spacing(@word_spacing)
        @last_word_spacing = @word_spacing
      end
      unless @char_spacing == @last_char_spacing
        tw.set_char_spacing(@char_spacing)
        @last_char_spacing = @char_spacing
      end
    end

    def check_set_scale
      unless @scale == @last_scale
        tw.set_horiz_scaling(@scale * 100)
        @last_scale = @scale
      end
    end

    # def check_set_scale
    #   unless @scale == @last_scale
    #     tw.set_horiz_scaling(@scale)
    #     @last_scale = @scale
    #   end
    # end

    def text_rendering_mode(options)
      if options[:fill] and options[:stroke]
        @text_rendering_mode = 2
      elsif options[:stroke]
        @text_rendering_mode = 1
      elsif options[:fill]
        @text_rendering_mode = 0
      elsif options[:invisible]
        @text_rendering_mode = 3 # Why is this an option in PDF?
      else
        @text_rendering_mode = 0
      end
    end

    def text_clipping_mode(options)
      if options[:fill] and options[:stroke]
        @text_rendering_mode = 6
      elsif options[:stroke]
        @text_rendering_mode = 5
      elsif options[:fill]
        @text_rendering_mode = 4
      else
        @text_rendering_mode = 7
      end
    end

    def check_set_text_rendering_mode
      unless @text_rendering_mode == @last_text_rendering_mode
        tw.set_rendering_mode(@text_rendering_mode)
        @last_text_rendering_mode = @text_rendering_mode
      end
    end

    # color methods
    def check_set_line_color
      unless @line_color == @last_line_color
        r, g, b = rgb_from_color(@line_color)
        if @in_path and @auto_path
          gw.stroke
          @in_path = false
        end
        if @in_misc
          mw.set_rgb_color_stroke(r / 255.0, g / 255.0, b / 255.0)
          @last_line_color = @line_color
        end
      end
    end

    def check_set_fill_color
      unless @fill_color == @last_fill_color
        r, g, b = rgb_from_color(@fill_color)
        if @in_path and @auto_path
          gw.stroke
          @in_path = false
        end
        if @in_misc
          mw.set_rgb_color_fill(r / 255.0, g / 255.0, b / 255.0)
          @last_fill_color = @fill_color
        end
      end
    end

    def check_set_font_color
      unless @font_color == @last_fill_color
        r, g, b = rgb_from_color(@font_color)
        if @in_path and @auto_path
          gw.stroke
          @in_path = false
        end
        if @in_misc
          mw.set_rgb_color_fill(r / 255.0, g / 255.0, b / 255.0)
          @last_fill_color = @font_color
        end
      end
    end

    def check_set_line_dash_pattern
      unless @line_dash_pattern == @last_line_dash_pattern
        if @in_path and @auto_path
          gw.stroke
          @in_path = false
        end

        if @line_dash_pattern.is_a?(Symbol)
          dashes = (LINE_PATTERNS[@line_dash_pattern] || []).map { |p| p * @line_width.round }
          pattern = gw.make_line_dash_pattern(dashes, 0)
        else
          @line_dash_pattern.to_s
        end

        gw.set_line_dash_pattern(pattern)
        @last_line_dash_pattern = @line_dash_pattern
      end
    end

    def check_set_line_width
      unless @line_width == @last_line_width
        if @in_path and @auto_path
          gw.stroke
          @in_path = false
        end

        gw.set_line_width(@line_width)
        @last_line_width = @line_width
        @last_line_dash_pattern = nil if @last_line_dash_pattern.is_a?(Symbol)
      end      
    end

    def check_set(*options)
      check_set_line_color          if options.include?(:line_color)
      check_set_fill_color          if options.include?(:fill_color)
      check_set_line_width          if options.include?(:line_width)
      check_set_line_dash_pattern   if options.include?(:line_dash_pattern)
      check_set_font                if options.include?(:font)
      check_set_font_color          if options.include?(:font_color)
      check_set_v_text_align        if options.include?(:v_text_align)
      check_set_spacing             if options.include?(:spacing)
      check_set_scale               if options.include?(:scale)
      check_set_text_rendering_mode if options.include?(:text_rendering_mode)
    end

    def line_colors
      @line_colors ||= ColorStack.new(self, :line_color)
    end

    def fill_colors
      @fill_colors ||= ColorStack.new(self, :fill_color)
    end

    def auto_stroke_and_fill(options)
      if @auto_path
        gw.clip if options[:clip]
        if (options[:stroke] and options[:fill])
          gw.fill_and_stroke
        elsif options[:stroke] then
          gw.stroke
        elsif options[:fill] then
          gw.fill
        else
          gw.new_path
        end
        @in_path = false
      end
    end

    # protected drawing methods
    def draw_rounded_rectangle(x, y, width, height, options)
      corners = options[:corners] || []
      if corners.size == 1
        xr1 = yr1 = xr2 = yr2 = xr3 = yr3 = xr4 = yr4 = corners[0]
      elsif corners.size == 2
        xr1 = yr1 = xr2 = yr2 = corners[0]
        xr3 = yr3 = xr4 = yr4 = corners[1]
      elsif corners.size == 4
        xr1 = yr1 = corners[0]
        xr2 = yr2 = corners[1]
        xr3 = yr3 = corners[2]
        xr4 = yr4 = corners[3]
      elsif corners.size == 8
        xr1, yr1, xr2, yr2, xr3, yr3, xr4, yr4 = corners
      else
        xr1 = yr1 = xr2 = yr2 = xr3 = yr3 = xr4 = yr4 = 0
      end

      q2p = get_quadrant_bezier_points(2, x         + xr1, y          + yr1, xr1, yr1)
      q1p = get_quadrant_bezier_points(1, x + width - xr2, y          + yr2, xr2, yr2)
      q4p = get_quadrant_bezier_points(4, x + width - xr3, y + height - yr3, xr3, yr3)
      q3p = get_quadrant_bezier_points(3, x         + xr4, y + height - yr4, xr4, yr4)

      qpa = [q1p, q2p, q3p, q4p]
      if options[:reverse]
        qpa.reverse!
        qpa.each { |qp| qp.reverse! }
      end

      curve_points(qpa[0]); line_to(qpa[1][0].x, qpa[1][0].y)
      curve_points(qpa[1]); line_to(qpa[2][0].x, qpa[2][0].y)
      curve_points(qpa[2]); line_to(qpa[3][0].x, qpa[3][0].y)
      curve_points(qpa[3]); line_to(qpa[0][0].x, qpa[0][0].y)
    end
    
    def draw_rectangle_path(x, y, width, height, options)
      move_to(x, y)
      if options[:reverse]
        line_to(x, y + height)
        line_to(x + width, y + height)
        line_to(x + width, y)
      else
        line_to(x + width, y)
        line_to(x + width, y + height)
        line_to(x, y + height)
      end
      line_to(x, y)
    end

    def draw_underline(pos1, pos2, position, thickness, angle)
      # position and thickness are in points
      if @units != :pt
        pos1, pos2 = convert_units(pos1, @units, :pt), convert_units(pos2, @units, :pt)
      end
      save_units = units(:pt)
      save_line_width = line_width(thickness)
      off_x, off_y = rotate_xy_coordinate(0, position - @v_text_align_pts, angle)
      move_to(pos1.x - off_x, pos1.y + off_y)
      line_to(pos2.x - off_x, pos2.y + off_y)
      line_width(save_line_width)
      units(save_units)
    end

  public
    DEFAULT_FONT = { :name => 'Helvetica', :size => 12 }

    attr_reader :doc, :page
    attr_reader :stream, :annotations
    attr_reader :auto_path

    def initialize(doc, options)
      # doc: PdfDocumentWriter
      @doc = doc
      @options = options
      @page_style = PageStyle.new(options)
      @units = options[:units] || :pt
      @v_text_align = options[:v_text_align] || :top
      @page_width = @page_style.page_size.x2
      @page_height = @page_style.page_size.y2
      if @page = options[:_page]
        @reused_page = true
      else
        @page = PdfObjects::PdfPage.new(@doc.next_seq, 0, @doc.catalog.pages)
        @page.media_box = @page_style.page_size.clone
        @page.crop_box = @page_style.crop_size.clone
        @page.rotate = @page_style.rotate
        @page.resources = @doc.resources
        @doc.file.body << @page
      end
      @stream = ''
      @annotations = []
      @char_spacing = @word_spacing = 0.0
      @last_char_spacing = @last_word_spacing = 0.0
      @last_scale = @scale = 1.0
      @last_text_rendering_mode = @text_rendering_mode = 0
      @default_font = options[:font] || DEFAULT_FONT
      @font_color = @default_font[:color] || 0
      @fill_color = options[:fill_color] || 0
      @line_color = options[:line_color] || 0
      @line_height = options[:line_height] || 1.7
      line_width(options[:line_width] || 1.0, :pt)
      @text_angle = 0.0
      @auto_path = true
      @underline = false
      start_misc
      sub_page(*options[:sub_page] + Array(options[:unscaled])) if options[:sub_page]
      margins(options[:margins] || 0)
    end

    def close
      end_margins unless @matrix.nil?
      end_sub_page unless @sub_page.nil?
      end_text if @in_text
      end_graph if @in_graph
      end_misc if @in_misc
      pdf_stream = if @options[:compress]
        require 'zlib'
        zipper = Zlib::Deflate.new
        zstream = zipper.deflate(@stream, Zlib::FINISH)
        zpdf_stream = PdfObjects::PdfStream.new(@doc.next_seq, 0, zstream)
        zpdf_stream.filter = 'FlateDecode'
        zpdf_stream
      else
        PdfObjects::PdfStream.new(@doc.next_seq, 0, @stream)
      end
      @doc.file.body << pdf_stream
      @page.annots = @annotations if @annotations.size.nonzero?
      @page.contents << pdf_stream
      @doc.catalog.pages.kids << @page unless @reused_page
      @stream = nil
    end

    def closed?
      @stream.nil?
    end

    # coordinate methods
    def units(units=nil)
      return @units if units.nil?
      @loc = convert_units(@loc, @units, units)
      @last_loc = convert_units(@last_loc, @units, units) unless @last_loc.nil?
      prev_units, @units = @units, units
      prev_units
    end

    def margins(*margins)
      @margins ||= [0] * 4
      return @margins.map { |m| from_points(@units, m) } unless [4,2,1].include?(margins.size)
      margins = margins.first if margins.first.is_a?(Array)
      @margins = case margins.size
        when 4: margins
        when 2: margins * 2
        when 1: margins * 4
        else @margins
        end.map { |m| to_points(@units, m) }
      @margin_top, @margin_right, @margin_bottom, @margin_left = @margins
      if (@matrix || IDENTITY_MATRIX)[4..5] != [@margin_left, -@margin_top]
        if @matrix.nil?
          @matrix = IDENTITY_MATRIX.dup
        else
          gw.restore_graphics_state
        end
        @matrix[4..5] = [@margin_left, -@margin_top]
        gw.save_graphics_state
        gw.concat_matrix(*@matrix)
      end
      @canvas_width = @page_width - @margin_left - @margin_right
      @canvas_height = @page_height - @margin_top - @margin_bottom
      move_to(0, 0)
      nil
    end

    def page_width
      from_points(@units, @page_width)
    end

    def page_height
      from_points(@units, @page_height)
    end

    def margin_top
      from_points(@units, @margin_top)
    end

    def margin_right
      from_points(@units, @margin_right)
    end

    def margin_bottom
      from_points(@units, @margin_bottom)
    end

    def margin_left
      from_points(@units, @margin_left)
    end

    def canvas_width
      from_points(@units, @canvas_width)
    end

    def canvas_height
      from_points(@units, @canvas_height)
    end

    # sub-page methods
    def sub_page(x, pages_across, y, pages_down, unscaled=false)
      unless @matrix.nil?
        gw.restore_graphics_state
        @matrix = nil
      end
      gw.restore_graphics_state unless @sub_page.nil?
      return unless x && pages_across && y && pages_down
      if unscaled
        @canvas_width = @page_width.quo(pages_across)
        @canvas_height = @page_height.quo(pages_down)
        @sub_page = IDENTITY_MATRIX.dup
        @sub_page[4] = @canvas_width * x
        @sub_page[5] = @canvas_height * (pages_down - 1 - y)
      else
        ps = PageStyle.new(@options.merge(:orientation => sub_orientation(pages_across, pages_down)))
        width = ps.page_size.x2
        height = ps.page_size.y2

        ratio_w = @page_width.quo(pages_across * width)
        ratio_h = @page_height.quo(pages_down * height)
        ratio = [ratio_w, ratio_h].min
        @sub_page = IDENTITY_MATRIX.dup
        @sub_page[0] = ratio
        @sub_page[3] = ratio
        @sub_page[4] = @page_width.quo(pages_across) * x
        @sub_page[5] = @page_height.quo(pages_down) * (pages_down - 1 - y)
        if ratio_w >= ratio_h
          @page_width, @page_height = width, height
        else
          @page_width, @page_height = width, width / ratio_w
        end
      end

      gw.save_graphics_state
      gw.concat_matrix(*@sub_page)
      @last_font = @last_page_font = nil
    end

    def move_to(x, y)
      @loc = translate(x, y)
      nil
    end

    def pen_pos(x=nil, y=nil)
      return translate(@loc.x, @loc.y) if x.nil?
      move_to(x, y)
    end

    def move_by(dx, dy)
      p = pen_pos
      move_to(p.x + dx, p.y + dy)
    end

    # graphics methods
    def line_to(x, y)
      unless @last_loc == @loc
        gw.stroke if @in_path and @auto_path
        @in_path = false
      end

      check_set(:line_color, :line_width, :line_dash_pattern)

      gw.move_to(to_points(@units, @loc.x), to_points(@units, @loc.y)) unless @in_path
      move_to(x, y)
      gw.line_to(to_points(@units, @loc.x), to_points(@units, @loc.y))
      @in_path = true
      @last_loc = @loc.clone
      nil
    end

    def rectangle(x, y, width, height, options={})
      border = options[:border].nil? ? true : options[:border]
      fill = options[:fill].nil? ? false : options[:fill]
      clip = options[:clip].nil? ? false : block_given?
      gw.stroke if @in_path and @auto_path

      line_colors.push(border)
      fill_colors.push(fill)
      check_set(:line_color, :line_width, :line_dash_pattern, :fill_color)

      if options[:corners]
        draw_rounded_rectangle(x, y, width, height, options)
      elsif options[:path]
        draw_rectangle_path(x, y, width, height, options)
      else
        gw.rectangle(
          to_points(@units, x),
          @page_height - to_points(@units, y + height),
          to_points(@units, width),
          to_points(@units, height))
      end

      gw.save_graphics_state if clip
      auto_stroke_and_fill(:stroke => border, :fill => fill, :clip => clip)
      yield if block_given?
      gw.restore_graphics_state if clip
      line_colors.pop
      fill_colors.pop
      move_to(x + width, y)
      nil
    end

    def curve(x0, y0, x1, y1, x2, y2, x3, y3)
      move_to(x0, y0)
      unless @last_loc == @loc
        if @in_path and @auto_path
          gw.stroke
          @in_path = false
        end
      end
      check_set(:line_color, :line_width, :line_dash_pattern)

      gw.move_to(to_points(@units, @loc.x), to_points(@units, @loc.y)) unless @in_path
      gw.curve_to(
          to_points(@units, x1),
          @page_height - to_points(@units, y1),
          to_points(@units, x2),
          @page_height - to_points(@units, y2),
          to_points(@units, x3),
          @page_height - to_points(@units, y3))
      move_to(x3, y3)
      @last_loc = @loc.clone
      @in_path = true
    end

    def curve_points(points)
      raise Exception.new("Need at least 4 points for curve") if points.size < 4
      move_to(points[0].x, points[0].y)
      unless @last_loc == @loc
        if @in_path and @auto_path
          gw.stroke
          @in_path = false
        end
      end

      check_set(:line_color, :line_width, :line_dash_pattern)

      gw.move_to(to_points(@units, @loc.x), to_points(@units, @loc.y)) unless (@loc == @last_loc) and @in_path
      i = 1
      while i + 2 < points.size
        gw.curve_to(
          to_points(@units, points[i].x),
          @page_height - to_points(@units, points[i].y),
          to_points(@units, points[i+1].x),
          @page_height - to_points(@units, points[i+1].y),
          to_points(@units, points[i+2].x),
          @page_height - to_points(@units, points[i+2].y)
        )
        move_to(points[i+2].x, points[i+2].y)
        @last_loc = @loc.clone
        i += 3
      end
      @in_path = true
    end

    # def curve_to(points)
    # end

    def points_for_circle(x, y, r)
      points = (1..4).inject([]) { |points, q| points + get_quadrant_bezier_points(q, x, y, r) }
      [12,8,4].each { |i| points.delete_at(i) }
      points
    end

    def circle(x, y, r, options={})
      border = options[:border].nil? ? true : options[:border]
      fill = options[:fill].nil? ? false : options[:fill]
      clip = options[:clip].nil? ? false : block_given?

      line_colors.push(border)
      fill_colors.push(fill)
      check_set(:line_color, :line_width, :line_dash_pattern, :fill_color)

      points = points_for_circle(x, y, r)
      points.reverse! if options[:reverse]
      curve_points(points)

      gw.save_graphics_state if clip
      auto_stroke_and_fill(:stroke => border, :fill => fill, :clip => clip)
      yield if block_given?
      gw.restore_graphics_state if clip
      line_colors.pop
      fill_colors.pop
      nil
    end

    def points_for_ellipse(x, y, rx, ry)
      points = (1..4).inject([]) { |points, q| points + get_quadrant_bezier_points(q, x, y, rx, ry) }
      [12,8,4].each { |i| points.delete_at(i) }
      points
    end

    def ellipse(x, y, rx, ry, options={})
      rotation = options[:rotation] || 0
      border = options[:border].nil? ? true : options[:border]
      fill = options[:fill].nil? ? false : options[:fill]
      clip = options[:clip].nil? ? false : block_given?

      line_colors.push(border)
      fill_colors.push(fill)
      check_set(:line_color, :line_width, :line_dash_pattern, :fill_color)

      points = points_for_ellipse(x, y, rx, ry)
      points = rotate_points(make_loc(x, y), points, -rotation)
      points.reverse! if options[:reverse]
      curve_points(points)

      gw.save_graphics_state if clip
      auto_stroke_and_fill(:stroke => border, :fill => fill, :clip => clip)
      yield if block_given?
      gw.restore_graphics_state if clip
      line_colors.pop
      fill_colors.pop
      nil
    end

    def points_for_arc(x, y, r, start_angle, end_angle)
      return nil if start_angle == end_angle

      num_arcs = 1
      ccwcw = 1.0
      arc_span = end_angle - start_angle
      if end_angle < start_angle
        ccwcw = -1.0
      end
      while arc_span.abs.quo(num_arcs) > 90.0
        num_arcs += 1
      end
      angle_bump = arc_span.quo(num_arcs)
      half_bump = 0.5 * angle_bump
      cur_angle = start_angle + half_bump
      points = []
      num_arcs.times do |i|
        points << points_for_arc_small(x, y, r, cur_angle, half_bump, ccwcw)
        points.last.shift if i > 0
        cur_angle = cur_angle + angle_bump
      end
      points.flatten
    end

    def arc(x, y, r, start_angle, end_angle, move_to0=false)
      return if start_angle == end_angle

      move_to0 = true unless @in_path
      num_arcs = 1
      ccwcw = 1.0
      arc_span = end_angle - start_angle
      if end_angle < start_angle
        ccwcw = -1.0
      end
      while arc_span.abs.quo(num_arcs) > 90.0
        num_arcs += 1
      end
      angle_bump = arc_span.quo(num_arcs)
      half_bump = 0.5 * angle_bump
      cur_angle = start_angle + half_bump
      num_arcs.times do
        arc_small(x, y, r, cur_angle, half_bump, ccwcw, move_to0)
        move_to0 = false
        cur_angle = cur_angle + angle_bump
      end
    end

    def pie(x, y, r, start_angle, end_angle, options={})
      border = options[:border].nil? ? true : options[:border]
      fill = options[:fill].nil? ? false : options[:fill]
      clip = options[:clip].nil? ? false : block_given?
      unless @last_loc == @loc
        gw.stroke if @in_path and @auto_path
        @in_path = false
      end

      line_colors.push(border)
      fill_colors.push(fill)
      check_set(:line_color, :line_width, :line_dash_pattern, :fill_color)

      move_to(x, y)
      gw.move_to(to_points(@units, @loc.x), to_points(@units, @loc.y))
      @last_loc = @loc.clone
      @in_path = true
      start_angle, end_angle = end_angle, start_angle if options[:reverse]
      arc(x, y, r, start_angle, end_angle)
      line_to(x, y)

      gw.save_graphics_state if clip
      auto_stroke_and_fill(:stroke => border, :fill => fill, :clip => clip)
      yield if block_given?
      gw.restore_graphics_state if clip
      line_colors.pop
      fill_colors.pop
      nil
    end

    def arch(x, y, r1, r2, start_angle, end_angle, options={})
      return if start_angle == end_angle
      start_angle, end_angle = end_angle, start_angle if options[:reverse]
      border = options[:border].nil? ? true : options[:border]
      fill = options[:fill].nil? ? false : options[:fill]
      clip = options[:clip].nil? ? false : block_given?
      unless @last_loc == @loc
        gw.stroke if @in_path and @auto_path
        @in_path = false
      end

      line_colors.push(border)
      fill_colors.push(fill)
      check_set(:fill_color)
      arc1 = points_for_arc(x, y, r1, start_angle, end_angle)
      arc2 = points_for_arc(x, y, r2, end_angle, start_angle)
      move_to(arc1.first.x, arc1.first.y)
      gw.move_to(to_points(@units, @loc.x), to_points(@units, @loc.y))
      curve_points(arc1)
      line_to(arc2.first.x, arc2.first.y)
      curve_points(arc2)
      line_to(arc1.first.x, arc1.first.y)
      
      gw.save_graphics_state if clip
      auto_stroke_and_fill(:stroke => border, :fill => fill, :clip => clip)
      yield if block_given?
      gw.restore_graphics_state if clip
      line_colors.pop
      fill_colors.pop
      nil
    end

    def points_for_polygon(x, y, r, sides, options={})
      step = 360.0 / sides
      angle = step / 2 + 90
      points = (0..sides).collect do
        px, py = rotate_xy_coordinate(r, 0, angle)
        angle += step
        make_loc(x + px * r, y + py * r)
      end
      rotation = options[:rotation] || 0
      points = rotate_points(make_loc(x, y), points, -rotation) unless rotation.zero?
      points.reverse! if options[:reverse]
      points
    end

    def polygon(x, y, r, sides, options={})
      border = options[:border].nil? ? true : options[:border]
      fill = options[:fill].nil? ? false : options[:fill]
      clip = options[:clip].nil? ? false : block_given?
      unless @last_loc == @loc
        gw.stroke if @in_path and @auto_path
        @in_path = false
      end

      points = points_for_polygon(x, y, r, sides, options)
      line_colors.push(border)
      fill_colors.push(fill)
      check_set(:line_color, :line_width, :line_dash_pattern, :fill_color)

      points.each_with_index do |point, i|
        if i == 0
          move_to(point.x, point.y)
        else
          line_to(point.x, point.y)
        end
      end
      gw.save_graphics_state if clip
      auto_stroke_and_fill(:stroke => border, :fill => fill, :clip => clip)
      yield if block_given?
      gw.restore_graphics_state if clip
      line_colors.pop
      fill_colors.pop
      nil
    end

    def star(x, y, r, points, options={})
      return if points < 5
      border = options[:border].nil? ? true : options[:border]
      fill = options[:fill].nil? ? false : options[:fill]
      clip = options[:clip].nil? ? false : block_given?
      unless @last_loc == @loc
        gw.stroke if @in_path and @auto_path
        @in_path = false
      end

      rotation = options[:rotation] || 0
      r2 = (points - 2).quo(points)
      vertices1 = points_for_polygon(x, y, r, points, options)
      vertices2 = points_for_polygon(x, y, r2, points, options.merge(:rotation => rotation + (360.0 / points / 2)))
      line_colors.push(border)
      fill_colors.push(fill)
      check_set(:line_color, :line_width, :line_dash_pattern, :fill_color)

      move_to(vertices2[0].x, vertices2[0].y)
      points.times do |i|
        line_to(vertices1[i].x, vertices1[i].y)
        line_to(vertices2[i+1].x, vertices2[i+1].y)
      end
      gw.save_graphics_state if clip
      auto_stroke_and_fill(:stroke => border, :fill => fill, :clip => clip)
      yield if block_given?
      gw.restore_graphics_state if clip
      line_colors.pop
      fill_colors.pop
      nil
    end

    def path(options={})
      stroke = options[:stroke].nil? ? false : options[:stroke]
      fill = options[:fill].nil? ? false : options[:fill]
      line_colors.push(stroke)
      fill_colors.push(fill)
      @auto_path = false
      if block_given?
        yield
        if options[:fill] and options[:stroke]
          gw.fill_and_stroke
        elsif options[:stroke]
          gw.stroke
        elsif options[:fill]
          gw.fill
        else
          gw.new_path
        end
        line_colors.pop
        fill_colors.pop
        @in_path = false
        @auto_path = true
      end
    end

    def fill
      raise Exception.new("Not in graph") unless @in_graph
      raise Exception.new("Not in path") unless @in_path

      check_set(:fill_color)
      gw.fill
      line_colors.pop
      fill_colors.pop
      @in_path = false
      @auto_path = true
    end

    def stroke
      raise Exception.new("Not in graph") unless @in_graph
      raise Exception.new("Not in path") unless @in_path

      check_set(:line_color)
      gw.stroke
      line_colors.pop
      fill_colors.pop
      @in_path = false
      @auto_path = true
    end

    def fill_and_stroke
      raise Exception.new("Not in graph") unless @in_graph
      raise Exception.new("Not in path") unless @in_path

      check_set(:fill_color,:line_color)
      gw.fill_and_stroke
      line_colors.pop
      fill_colors.pop
      @in_path = false
      @auto_path = true
    end

    def clip(options={})
      gw.save_graphics_state
      if @in_path
        gw.clip
        if options[:fill] and options[:stroke]
          gw.fill_and_stroke
        elsif options[:stroke]
          gw.stroke
        elsif options[:fill]
          gw.fill
        else
          gw.new_path
        end
      end
      save_text_rendering_mode = @text_rendering_mode
      text_clipping_mode(options)
      yield if block_given?
      # gw.clip
      gw.restore_graphics_state
      @text_rendering_mode = save_text_rendering_mode
      @in_path = false
      @auto_path = true
    end

    def line_dash_pattern(pattern=nil)
      return @line_dash_pattern if pattern.nil?
      prev_line_dash_pattern, @line_dash_pattern = @line_dash_pattern, pattern
      prev_line_dash_pattern
    end

    def line_width(width=nil, units=nil)
      return from_points(@units, @line_width || 0) if width.nil?
      return from_points(width, @line_width || 0) if width.is_a?(Symbol)
      prev_line_width = @line_width || 0
      if !units.nil?
        u, width = units.to_sym, width.to_f
      elsif width.respond_to?(:to_str) and width =~ /\D+/
        u, width = $&.to_sym, width.to_f
      else
        u = @units
      end
      @line_width = to_points(u, width)
      from_points(@units, prev_line_width)
    end

    def line_height(height=nil)
      return @line_height if height.nil?
      prev_line_height, @line_height = @line_height, height
      prev_line_height
    end

    # color methods
    def named_colors
      @doc.named_colors
    end

    def line_color(color=nil)
      return @line_color if color.nil?
      if color.is_a?(Array)
        r, g, b = color
        prev_line_color, @line_color = @line_color, color_from_rgb(r, g, b)
      else
        prev_line_color, @line_color = @line_color, color
      end
      prev_line_color
    end

    # def set_fill_color_rgb(red, green, blue)
    # end

    def fill_color(color=nil)
      return @fill_color if color.nil?
      if color.is_a?(Array)
        r, g, b = color
        prev_fill_color, @fill_color = @fill_color, color_from_rgb(r, g, b)
      else
        prev_fill_color, @fill_color = @fill_color, color
      end
      prev_fill_color
    end

    def font_color(color=nil)
      return @font_color if color.nil?
      if color.is_a?(Array)
        r, g, b = color
        prev_font_color, @font_color = @font_color, color_from_rgb(r, g, b)
      else
        prev_font_color, @font_color = @font_color, color
      end
      prev_font_color
    end

    def print(text, options={})
      return if text.empty?
      align = options[:align]
      angle = options[:angle] || 0.0
      @scale = options[:scale] || 1.0
      prev_underline = underline(options[:underline]) unless options[:underline].nil?
      clip = options[:clip] and block_given?
      if clip
        gw.save_graphics_state
        text_clipping_mode(options)
      end
      start_text unless @in_text
      check_set(:font, :font_color, :line_color, :v_text_align, :spacing, :scale, :text_rendering_mode)
      ds = width(text)
      if align
        prev_loc = @loc.clone
        @loc = case align
        when :left then @loc
        when :center then add_vector(@loc, angle + 180, ds.quo(2))
        when :right then add_vector(@loc, angle + 180, ds)
        end
      end
      if (@text_angle != angle) or (angle != 0.0)
        set_text_angle(angle, @loc.x, @loc.y)
      elsif @loc != @last_loc
        tw.move_by(to_points(@units, @loc.x - @last_loc.x), to_points(@units, @loc.y - @last_loc.y))
      end
      if @ic.nil?
        tw.show(text)
      else
        text = @ic.iconv(text)
        tw.show_wide(text)
      end
      @last_loc = @loc.clone
      new_loc = (angle == 0.0) ? Location.new(@loc.x + ds, @loc.y) : add_vector(@loc, angle, ds)
      draw_underline(translate_p(@last_loc), translate_p(new_loc), @font.underline_position, @font.underline_thickness, angle) if @underline
      underline(prev_underline) unless options[:underline].nil?
      @loc = align ? prev_loc : new_loc
      if clip
        yield
        gw.restore_graphics_state
      end
      nil
    end

    def print_xy(x, y, text, options={}, &block)
      move_to(x, y)
      print(text, options, &block)
    end

    def puts(text='', options={}, &block)
      # if it's not a real string, assume it's an enumeration of strings
      unless text.respond_to?(:to_str)
        text.each { |t| puts(t, options) }
      else
        save_loc = @loc.clone
        print(text, options, &block)
        @loc = Location.new(save_loc.x, save_loc.y - height)
      end
      nil
    end

    def puts_xy(x, y, text, options={}, &block)
      move_to(x, y)
      puts(text, options, &block)
    end

    def new_line(count=1)
      @loc = Location.new(@loc.x, @loc.y - height * count)
      nil
    end

    def width(text)
      set_default_font if @font.nil?
      result = 0.0
      fsize = @font.size * 0.001
      if @ic.nil?
        text.each_byte do |b|
          result += fsize * @font.widths[b] + @char_spacing
          result += @word_spacing if b == 32 # space
        end
      else
        text.unpack('n*').each do |cp|
          result += fsize * @font.widths[cp] + @char_spacing
          result += @word_spacing if cp == 32 # space
        end
      end
      from_points(@units, result - @char_spacing)
    end

    def wrap(text, width)
      re = /\n|\t|[ ]|[\S]+-+|[\S]+/
      words = text.scan(re)
      word_tuples = words.map { |word| [width(word), word] }
      line_length = 0
      lines = word_tuples.inject(['']) do |lines, tuple|
        if tuple[1] == "\n"
          lines << ''
          line_length = 0
        elsif line_length == 0
          unless tuple[1] == ' '
            lines.last << tuple[1]
            line_length += tuple[0]
          end
        elsif line_length + tuple[0] > width
          lines << ''
          line_length = 0
          redo
        else          
          lines.last << tuple[1]
          line_length += tuple[0]
        end
        lines
      end
    end

    def height(text='', units=nil) # may not include external leading?
      units ||= @units
      set_default_font if @font.nil?
      if text.respond_to?(:to_str)
        0.001 * @font.height * @font.size.quo(UNIT_CONVERSION[units]) * @line_height
      else
        text.inject(0) { |total, line| total + height(line, units) }
      end
    end

    def paragraph(text, options={})
      width = options[:width] || page_width - pen_pos.x
      height = options[:height] || page_height - pen_pos.y
      unless text.is_a?(PdfText::RichText)
        text = PdfText::RichText.new(text, @font,
          :color => @font_color, :char_spacing => @char_spacing, :word_spacing => @word_spacing, :underline => @underline)
      end
      dy = 0
      while dy + from_points(@units, text.height) < height and line = text.next(to_points(@units, width))
        save_loc = pen_pos
        line_dy = line.height.quo(UNIT_CONVERSION[units]) * @line_height
        case options[:align]
        when :center then move_to(save_loc.x + (width - from_points(@units, line.width)) / 2.0, save_loc.y)
        when :right then move_to(save_loc.x + width - from_points(@units, line.width), save_loc.y)
        when :justify then
          width_pt = to_points(@units, width)
          delta_pt = width_pt - line.width
          if delta_pt.quo(width_pt) < 0.2
            if delta_pt / (line.tokens - 1) > 3
              @word_spacing = 3
              delta_pt -= (line.tokens - 1) * @word_spacing
              @char_spacing = delta_pt / line.chars
            else
              @word_spacing = delta_pt / (line.tokens - 1) * 2
              @char_spacing = 0
            end
          end
        end
        while piece = line.shift
          @font = piece.font
          font_color piece.color
          underline piece.underline
          print(piece.text)
        end
        @word_spacing = @char_spacing = 0.0 if options[:align] == :justify
        dy += line_dy
        move_to(save_loc.x, save_loc.y + line_dy)
      end
      return text.empty? ? nil : text
    end

    def paragraph_xy(x, y, text, options={})
      move_to(x, y)
      paragraph(text, options)
    end

    def v_text_align(vta=nil)
      return @v_text_align if vta.nil?
      @v_text_align = vta
    end

    def underline(underline=nil)
      return @underline if underline.nil?
      prev_underline, @underline = @underline, underline
      prev_underline
    end

    # font methods
    def type1_font_names
      @doc.type1_font_names
    end

    def truetype_font_names
      @doc.truetype_font_names
    end

    def select_font(name, size, options={})
      unless @ic.nil?
        @ic.close
        @ic = nil
      end
      font = Font.new(name, size, options[:style] || '', options[:color], pdf_encoding(options[:encoding] || 'WinAnsiEncoding'))
      font.sub_type = options[:sub_type] || 'Type1'
      punc = (font.sub_type == 'TrueType') ? ',' : '-'
      full_name = name.gsub(' ','')
      full_name << punc << font.style unless font.style.empty?
      font_key = "#{full_name}/#{font.encoding}-#{font.sub_type}"
      if font.sub_type == 'Type1'
        metrics = @options[:built_in_fonts] ? PdfK::font_metrics(full_name) : AFM::font_metrics(full_name, :encoding => font.encoding)
      elsif font.sub_type == 'TrueType'
        if @options[:built_in_fonts]
          metrics = PdfTT::font_metrics(full_name)
        else
          raise Exception.new("Non-built-in TrueType fonts not supported yet.")
        end
      elsif font.sub_type == 'Type0'
        metrics = AFM::font_metrics(full_name, :encoding => :unicode)
        require 'iconv'
        @ic = Iconv.new('UCS-2BE', iconv_encoding(font.encoding))
      else
        raise Exception.new("Unsupported subtype #{font.sub_type}.")
      end
      font.widths, font.ascent, font.descent = metrics.widths, metrics.ascent, metrics.descent
      font.height = font.ascent + font.descent.abs
      font.underline_position = metrics.underline_position * -0.001 * font.size
      font.underline_thickness = metrics.underline_thickness * 0.001 * font.size
      page_font = @doc.fonts[font_key]
      unless page_font
        widths = nil
        if metrics.needs_descriptor
          descriptor = PdfObjects::PdfFontDescriptor.new(@doc.next_seq, 0, full_name, metrics.flags, metrics.b_box, 
            metrics.missing_width, metrics.stem_v, metrics.stem_h, metrics.italic_angle,
            metrics.cap_height, metrics.x_height, metrics.ascent, metrics.descent, metrics.leading,
            metrics.max_width, metrics.avg_width)
          @doc.file.body << descriptor
          widths = PdfObjects::IndirectObject.new(@doc.next_seq, 0, PdfObjects::PdfInteger.ary(metrics.widths))
          @doc.file.body << widths
        else
          descriptor = nil
          widths = nil
        end
        page_font = "F#{@doc.fonts.size}"
        f = PdfObjects::PdfFont.new(@doc.next_seq, 0, font.sub_type, full_name, 0, 255, widths, descriptor)
        @doc.file.body << f
        if PdfObjects::PdfFont.standard_encoding?(font.encoding)
          f.encoding = font.encoding
        else
          encoding = @doc.encodings[font.encoding]
          if encoding.nil?
            encoding = PdfObjects::PdfFontEncoding.new(@doc.next_seq, 0, 'WinAnsiEncoding', metrics.differences)
            @doc.encodings[font.encoding] = encoding
            @doc.file.body << encoding
          end
          f.encoding = encoding.reference_object
          # raise Exception.new("Unsupported encoding #{font.encoding}")
        end
        @doc.resources.fonts[page_font] = f.reference_object
        @doc.fonts[font_key] = page_font
      end
      font_color(options[:color]) if options[:color]
      text_rendering_mode(options)
      [font, page_font]
    end

    def font(name=nil, size=nil, options={})
      return @font || set_default_font if name.nil?
      size ||= @font.nil? ? @default_font[:size] : @font.size
      @font, @page_font = select_font(name, size, options)
      @font
    end

    def font_style(style=nil)
      set_default_font if @font.nil?
      return @font.style if style.nil?
      prev_style = @font.style
      font(@font.name, @font.size, :style => style, :color => @font.color, :encoding => @font.encoding, :sub_type => @font.sub_type)
      prev_style
    end

    def font_size(size=nil)
      set_default_font if @font.nil?
      return @font.size if size.nil?
      prev_size = @font.size
      font(@font.name, size, :style => @font.style, :color => @font.color, :encoding => @font.encoding, :sub_type => @font.sub_type)
      prev_size
    end

    # image methods
    def jpeg?(image)
      image[0, 2] == "\xFF\xD8"
    end

    def jpeg_dimensions(image)
      raise "Not a JPEG" unless jpeg?(image)
      image = image.dup
      image.slice!(0, 2) # delete jpeg marker
      while marker = image.slice!(0, 4)
        m, c, l = marker.unpack('aan')
        raise "Bad JPEG" unless m == "\xFF"
        if ["\xC0", "\xC1", "\xC2", "\xC3", "\xC5", "\xC6", "\xC7", "\xC9", "\xCA", "\xCB", "\xCD", "\xCE", "\xCF"].include?(c)
          dims = image.slice(0, 6)
          bits_per_component, height, width, components = dims.unpack('CnnC')
          break
        end
        image.slice!(0, l - 2)
      end
      [width, height, components, bits_per_component]
    end

    def load_image(image_file_name, stream=nil)
      image, name = @doc.images[image_file_name]
      return [image, name] unless image.nil?
      stream ||= IO.read(image_file_name)
      image = PdfObjects::PdfImage.new(@doc.next_seq, 0, stream)
      image.width, image.height, components, image.bits_per_component = jpeg_dimensions(stream)
      image.color_space = { 1 => 'DeviceGray', 3 => 'DeviceRGB', 4 => 'DeviceCMYK' }[components]
      image.filter = 'DCTDecode'
      name = "Im#{@doc.images.size}"
      @doc.file.body << image
      @doc.resources.x_objects[name] = image.reference_object
      @doc.images[image_file_name] = [image, name]
      [image, name]
    end

    def print_image_file(image_file_name, x=nil, y=nil, width=nil, height=nil)
      image, name = load_image(image_file_name)
      x ||= pen_pos.x
      y ||= pen_pos.y
      if width.nil? and height.nil?
        width, height = image.width, image.height
      elsif width.nil?
        height = to_points(@units, height)
        width = height * image.width.quo(image.height)
      elsif height.nil?
        width = to_points(@units, width)
        height = width * image.height.quo(image.width)
      end
      end_path if @in_path
      gw.save_graphics_state
      gw.concat_matrix(width, 0, 0, height, to_points(@units, x), to_points(@units, page_height - y) - height)
      mw.x_object(name)
      gw.restore_graphics_state
      [from_points(@units, width), from_points(@units, height)]
    end

    def print_image(data, x=nil, y=nil, width=nil, height=nil)
      image_file_name = data.hash.to_s
      image, name = load_image(image_file_name, data)
      print_image_file(image_file_name, x, y, width, height)
    end

    def print_link(s, uri)
    end

    def tabs(tabs=nil)
      return @tabs if tabs.nil?
      return @tabs = nil if tabs == false or tabs.empty?
      tabs = tabs.split(',') if tabs.respond_to?(:to_str)
      @tabs = tabs.map { |stop| stop.to_f }.select { |stop| stop > 0 }.sort
    end

    def tab
      return if @tabs.nil?
      p = pen_pos
      x = @tabs.detect { |stop| stop > p.x }
      if x.nil?
        dy = block_given? ? yield : height
        move_to(@tabs.first, p.y + dy)
      else
        move_to(x, p.y)
      end
    end

    def vtabs(tabs=nil)
      return @vtabs if tabs.nil?
      return @vtabs = nil if tabs == false or tabs.empty?
      tabs = tabs.split(',') if tabs.respond_to?(:to_str)
      @vtabs = tabs.map { |stop| stop.to_f }.select { |stop| stop > 0 }.sort
    end

    def vtab
      return if @vtabs.nil?
      p = pen_pos
      y = @vtabs.detect { |stop| stop > p.y }
      if y.nil?
        move_to(p.x + yield, @vtabs.first) if block_given?
      else
        move_to(p.x, y)
      end
    end
  end

  class DocumentWriter
    def next_seq
      @next_seq += 1
    end

    attr_reader :pages
    attr_reader :catalog, :file, :resources
    attr_reader :fonts, :images, :encodings
    attr_reader :in_page

    # instantiation
    def initialize
      @fonts = {}
      @images = {}
      @encodings = {}
    end

    def to_s
      @file.to_s
    end

    # document methods
    def open(options={})
      raise Exception.new("Already in document") if @in_doc
      @in_doc = true
      @options = options
      @pages = []
      @next_seq = 0
      @file = PdfObjects::PdfFile.new
      pages = PdfObjects::PdfPages.new(next_seq, 0)
      outlines = PdfObjects::PdfOutlines.new(next_seq, 0)
      @catalog = PdfObjects::PdfCatalog.new(next_seq, 0, :use_none, pages, outlines)
      @file.body << pages << outlines << @catalog
      @file.trailer.root = @catalog
      define_resources
      @pages_across, @pages_down = options[:pages_up] || [1, 1]
      @pages_up = @pages_across * @pages_down
    end

    def close
      open_page if @pages.empty? # empty document needs at least one page
      close_page if @in_page
      @pages.each { |page| page.close unless page.closed? }
    end

    def doc(options={})
      open(options)
      yield(self)
      close
    end

    # page methods
    def open_page(options={})
      raise Exception.new("Already in page") if @in_page
      options.update(:_page => pdf_page(@pages.size), :sub_page => sub_page(@pages.size))
      @cur_page = PageWriter.new(self, @options.merge(options))
      @pages << @cur_page
      @in_page = true
      return @cur_page
    end

    def close_page
      raise Exception.new("Not in page") unless @in_page
      @cur_page.close
      @cur_page = nil
      @in_page = false
    end

    def page(options={})
      cur_page = open_page(options)
      yield(cur_page)
      close_page
    end

    def new_page(options={})
      close_page
      open_page(options)
    end

    def cur_page
      @cur_page || open_page
    end

    # coordinate methods
    def units(units=nil)
      cur_page.units(units)
    end

    def margins(*margins)
      cur_page.margins(*margins)
    end

    def margin_top
      cur_page.margin_top
    end

    def margin_right
      cur_page.margin_right
    end

    def margin_bottom
      cur_page.margin_bottom
    end

    def margin_left
      cur_page.margin_left
    end

    def canvas_width
      cur_page.canvas_width
    end

    def canvas_height
      cur_page.canvas_height
    end

    def page_width
      cur_page.page_width
    end

    def page_height
      cur_page.page_height
    end

    def line_height(height=nil)
      cur_page.line_height(height)
    end

    def move_to(x, y)
      cur_page.move_to(x, y)
    end

    def pen_pos(x=nil, y=nil)
      cur_page.pen_pos(x, y)
    end

    def move_by(dx, dy)
      cur_page.move_by(dx, dy)
    end

    # graphics methods
    def line_to(x, y)
      cur_page.line_to(x, y)
    end

    def rectangle(x, y, width, height, options={})
      cur_page.rectangle(x, y, width, height, options)
    end

    def curve(x0, y0, x1, y1, x2, y2, x3, y3)
      cur_page.curve(x0, y0, x1, y1, x2, y2, x3, y3)
    end

    def curve_points(points)
      cur_page.curve_points(points)
    end

    # def curve_to(points)
    #   cur_page.curve_to(points)
    # end

    def points_for_circle(x, y, r)
      cur_page.points_for_circle(x, y, r)
    end

    def circle(x, y, r, options={})
      cur_page.circle(x, y, r, options)
    end

    def points_for_ellipse(x, y, rx, ry)
      cur_page.points_for_ellipse(x, y, rx, ry)
    end

    def ellipse(x, y, rx, ry, options={})
      cur_page.ellipse(x, y, rx, ry, options)
    end

    def points_for_arc(x, y, r, start_angle, end_angle)
      cur_page.points_for_arc(x, y, r, start_angle, end_angle)
    end

    def arc(x, y, r, start_angle, end_angle, move_to0=false)
      cur_page.arc(x, y, r, start_angle, end_angle, move_to0)
    end

    def pie(x, y, r, start_angle, end_angle, options={})
      cur_page.pie(x, y, r, start_angle, end_angle, options)
    end

    def arch(x, y, r1, r2, start_angle, end_angle, options={})
      cur_page.arch(x, y, r1, r2, start_angle, end_angle, options)
    end

    def points_for_polygon(x, y, r, sides, options={})
      cur_page.points_for_polygon(x, y, r, sides, options)
    end

    def polygon(x, y, r, sides, options={})
      cur_page.polygon(x, y, r, sides, options)
    end

    def star(x, y, r, points, options={})
      cur_page.star(x, y, r, points, options)
    end

    def path(options={}, &block)
      cur_page.path(options, &block)
    end

    def fill
      cur_page.fill
    end

    def stroke
      cur_page.stroke
    end

    def fill_and_stroke
      cur_page.fill_and_stroke
    end

    def clip(options={})
      cur_page.clip(options)
    end

    def line_dash_pattern(pattern=nil)
      cur_page.line_dash_pattern(pattern)
    end

    def line_width(width=nil, units=nil)
      cur_page.line_width(width, units)
    end

    # color methods
    def named_colors
      @named_colors ||= PdfK::NAMED_COLORS
    end

    def line_color(color=nil)
      cur_page.line_color(color)
    end

    def fill_color(color=nil)
      cur_page.fill_color(color)
    end

    def font_color(color=nil)
      cur_page.font_color(color)
    end

    # text methods
    def print(text, options={}, &block)
      cur_page.print(text, options, &block)
    end

    def print_xy(x, y, text, options={}, &block)
      cur_page.print_xy(x, y, text, options, &block)
    end

    def puts(text='', options={}, &block)
      cur_page.puts(text, options, &block)
    end

    def puts_xy(x, y, text, options={}, &block)
      cur_page.puts_xy(x, y, text, options={}, &block)
    end

    def new_line(count=1)
      cur_page.new_line(count)
    end

    def width(text)
      cur_page.width(text)
    end

    def wrap(text, length)
      cur_page.wrap(text, length)
    end

    def height(text='', units=nil) # may not include external leading?
      cur_page.height(text, units)
    end

    def paragraph(text, options={})
      cur_page.paragraph(text, options)
    end

    def paragraph_xy(x, y, text, options={})
      cur_page.paragraph_xy(x, y, text, options)
    end

    def v_text_align(vta=nil)
      cur_page.v_text_align(vta)
    end

    # font methods
    def type1_font_names
      if @options[:built_in_fonts]
        PdfK::FONT_NAMES
      else
        AFM::font_names
      end
    end

    def truetype_font_names
      if @options[:built_in_fonts]
        PdfTT::FONT_NAMES
      else
        raise Exception.new("Non-built-in TrueType fonts not supported yet.")
      end
    end

    def font(name=nil, size=nil, options={})
      cur_page.font(name, size, options)
    end

    def font_style(style=nil)
      cur_page.font_style(style)
    end

    def font_size(size=nil)
      cur_page.font_size(size)
    end

    # image methods
    def jpeg?(image)
      cur_page.jpeg?(image)
    end

    def jpeg_dimensions(image)
      cur_page.jpeg_dimensions(image)
    end

    def load_image(image_file_name, stream=nil)
      cur_page.load_image(image_file_name, stream)
    end

    def print_image_file(image_file_name, x=nil, y=nil, width=nil, height=nil)
      cur_page.print_image_file(image_file_name, x, y, width, height)
    end

    def print_image(data, x=nil, y=nil, width=nil, height=nil)
      cur_page.print_image(data, x, y, width, height)
    end

    def print_link(s, uri)
      cur_page.print_link(s, uri)
    end

    def tabs(tabs=nil)
      cur_page.tabs(tabs)
    end

    def tab(&block)
      cur_page.tab(&block)
    end

    def vtabs(tabs=nil)
      cur_page.vtabs(tabs)
    end

    def vtab(&block)
      cur_page.vtab(&block)
    end

  protected
    def define_resources
      @resources = PdfObjects::PdfResources.new(next_seq, 0)
      @resources.proc_set = PdfObjects::PdfName.ary ['PDF','Text','ImageB','ImageC']
      @file.body << @resources
    end

    def make_font_descriptor(font_name)
    end

    def sub_page(page_no)
      if @pages_up == 1
        nil
      elsif @options[:pages_up_layout] == :down
        [page_no % @pages_down, @pages_across, (page_no / @pages_down) % @pages_across, @pages_down]
      else
        [page_no % @pages_across, @pages_across, (page_no / @pages_across) % @pages_down, @pages_down]
      end
    end

    def pdf_page(page_no)
      if page = @pages[page_no / @pages_up * @pages_up]
        page.page
      else
        nil
      end
    end
  end
end
