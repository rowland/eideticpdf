#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-07-13.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

require 'pdfu'
require 'pdfk'

module PdfW
  include PdfU

  Font = Struct.new(:name, :size, :style, :color, :encoding, :sub_type, :widths, :ascent, :descent, :height)
  Location = Struct.new(:x, :y)
  Signs = Struct.new(:x, :y)

  SIGNS = [ Signs.new(1, -1), Signs.new(-1, -1), Signs.new(-1, 1), Signs.new(1, 1) ]
  UNIT_CONVERSION = { :pt => 1, :in => 72, :cm => 28.35 }

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
      # @rotate = ROTATIONS[@orientation]
    end

    SIZES = {
      :letter => {
        :portrait => [0,0,612,792].freeze,
        :landscape => [0,0,792,612].freeze        
      }.freeze,
      :legal => {
        :portrait => [0,0,612,1008].freeze,
        :landscape => [0,0,1008,612].freeze
      }.freeze,
      :A4 => {
        :portrait => [0,0,595,842].freeze,
        :landscape => [0,0,842,595].freeze
      }.freeze,
      :B5 => {
        :portrait => [0,0,499,708].freeze,
        :landscape => [0,0,708,499].freeze
      }.freeze,
      :C5 => {
        :portrait => [0,0,459,649].freeze,
        :landscape => [0,0,649,459].freeze
      }.freeze
    }
    ROTATIONS = { :portrait => PORTRAIT, :landscape => LANDSCAPE }.freeze

  protected
    def make_size_rectangle(size, orientation)
      Rectangle.new(*(SIZES[size][orientation]))
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

    def clip
      @stream << "W\n"
    end

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
      @stream << "(%s) Tj\n" % PdfString.escape(s)
    end

    def next_line_show(s)
      @stream << "(%s) '" % PdfString.escape(s)
    end

    def set_spacing_next_line_show(char_space, word_space, s)
      @stream << "%s %s (%s) \"\n" % [g(char_space), g(word_space), PdfString.escape(s)]
    end

    def show_with_dispacements(elements)
      @stream << "%sTJ\n" % elements
    end
  end

  class PdfPageWriter
  private
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
      measurement / UNIT_CONVERSION[units].to_f
    end

    def convert_units(loc, from_units, to_units)
      Location.new(
        loc.x * UNIT_CONVERSION[from_units] / UNIT_CONVERSION[to_units].to_f,
        loc.y * UNIT_CONVERSION[from_units] / UNIT_CONVERSION[to_units].to_f)
    end

    def get_quadrant_bezier_points(quadrant, x, y, rx, ry=nil)
      ry = rx if ry.nil?
      a = 4.0 / 3.0 * (Math.sqrt(2) - 1.0)
      bp = []
      if odd?(quadrant) # quadrant is odd
        # (1,0)
        bp << Location.new(x + (rx * SIGNS[quadrant - 1].x), y)
        # (1,a)
        bp << Location.new(bp[0].x, y + (a * ry * SIGNS[quadrant - 1].y))
        # (a,1)
        bp << Location.new(x + (a * rx * SIGNS[quadrant - 1].x), y + (ry * SIGNS[quadrant - 1].y))
        # (0,1)
        bp << Location.new(x, bp[2].y)
      else # quadrant is even
        # (0,1)
        bp << Location.new(x, y + (ry * SIGNS[quadrant - 1].y))
        # (a,1)
        bp << Location.new(x + (a * rx * SIGNS[quadrant - 1].x), bp[0].y)
        # (1,a)
        bp << Location.new(x + (rx * SIGNS[quadrant - 1].x), y + (a * ry * SIGNS[quadrant - 1].y))
        # (1,0)
        bp << Location.new(bp[2].x, y)
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
  		Location.new(x, y)
  	end

  	def rotate_points(mid, points, angle)
      theta = radians_from_degrees(angle)
      r_cos = Math::cos(theta)
      r_sin = Math::sin(theta)
  	  points.map do |p|
  	    x, y = p.x - mid.x, p.y - mid.y
        x_rot = (r_cos * x) - (r_sin * y)
        y_rot = (r_sin * x) + (r_cos * y)
  	    Location.new(x_rot + mid.x, y_rot + mid.y)
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
      [Location.new(x+x0, y-y0), Location.new(x+x1, y-y1), Location.new(x+x2, y-y2), Location.new(x+x3, y-y3)]
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
      color = PdfK::NAMED_COLORS[color] || 0 if color.respond_to? :to_str
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
      @tw = TextWriter.new(@stream)
      @tw.open
      @in_text = true
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
      @gw = GraphWriter.new(@stream)
      @in_graph = true
    end

    def end_graph
      raise Exception.new("Not in graph") unless @in_graph
      if @in_path
        gw.stroke if @auto_path
        @in_path = false
      end
      @gw = nil
      @in_graph = false
    end

    def start_misc
      raise Exception.new("Already in misc") if @in_misc
      @mw = MiscWriter.new(@stream)
      @in_misc = true
    end

    def end_misc
      raise Exception.new("Not in misc") unless @in_misc
      @mw = nil
      @in_misc = false
    end

    attr_reader :tw, :gw, :mw

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

    def check_set_v_text_align(force=false)
      if force or @last_v_text_align != @v_text_align
        if @v_text_align == :above
          @tw.set_rise(-@font.height * 0.001 * @font.size)
        elsif @v_text_align == :top
          @tw.set_rise(-@font.ascent * 0.001 * @font.size)
        elsif @v_text_align == :middle
          @tw.set_rise(-@font.ascent * 0.001 * @font.size / 2.0)
        elsif @v_text_align == :below
          @tw.set_rise(-@font.descent * 0.001 * @font.size)
        else # @v_text_align == :base
          @tw.set_rise(0.0)
        end
        @last_v_text_align = @v_text_align
      end
    end

    def check_set_font
      if (@last_page_font != @page_font) or (@last_font != @font)
        @tw.set_font_and_size(@page_font, @font.size)
        check_set_v_text_align(true)
        @last_page_font = @page_font
        @last_font = @font
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
        start_graph unless @in_graph
        if @in_path and @auto_path
          gw.stroke
          @in_path = false
        end

        gw.set_line_dash_pattern(@line_dash_pattern)
        @last_line_dash_pattern = @line_dash_pattern
      end      
    end

    def check_set_line_width
      unless @line_width == @last_line_width
        start_graph unless @in_graph
        if @in_path and @auto_path
          gw.stroke
          @in_path = false
        end

        gw.set_line_width(@line_width)
        @last_line_width = @line_width
      end      
    end

    def check_set(*options)
      check_set_line_color if options.include?(:line_color)
      check_set_line_width if options.include?(:line_width)
      check_set_line_dash_pattern if options.include?(:line_dash_pattern)
      check_set_fill_color if options.include?(:fill_color)
    end

    def line_color_stack
      @line_color_stack ||= []
    end

    def push_line_color(color)
      line_color_stack.push(@line_color)
      self.line_color = color if color.respond_to?(:to_int) or color.respond_to?(:to_str)
    end

    def pop_line_color
      color = line_color_stack.pop
      self.line_color = color if color.respond_to?(:to_int) or color.respond_to?(:to_str)
    end

    def fill_color_stack
      @fill_color_stack ||= []
    end

    def push_fill_color(color)
      fill_color_stack.push(@fill_color)
      self.fill_color = color if color.respond_to?(:to_int) or color.respond_to?(:to_str)
    end

    def pop_fill_color
      color = fill_color_stack.pop
      self.fill_color = color if color.respond_to?(:to_int) or color.respond_to?(:to_str)
    end

    def auto_stroke_and_fill(options)
      if @auto_path
        if (options[:stroke] and options[:fill])
          gw.fill_and_stroke
        elsif options[:stroke] then
          gw.stroke
        elsif options[:fill] then
          gw.fill
        end
        @in_path = false
      end
    end

    # protected drawing methods
    def draw_rounded_rectangle(x, y, width, height, options={})
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
  public
    attr_reader :doc, :units
    attr_reader :stream, :annotations
    attr_accessor :v_text_align
    attr_accessor :line_height
    attr_reader :auto_path

    def initialize(doc, options)
      # doc: PdfDocumentWriter
      @doc = doc
      @page_style = PageStyle.new(options)
      @loc = Location.new(0, @page_style.page_size.y2)
      @units = options[:units] || :pt
      @v_text_align = options[:v_text_align] || :top
      @page_width = @page_style.page_size.x2
      @page_height = @page_style.page_size.y2
      @page = PdfPage.new(@doc.next_seq, 0, @doc.catalog.pages)
      @page.media_box = @page_style.page_size.clone
      @page.crop_box = @page_style.crop_size.clone
      @page.rotate = @page_style.rotate
      @page.resources = @doc.resources
      @doc.file.body << @page
      @stream = ''
      @annotations = []
      @char_spacing = @word_spacing = 0.0
      @font_color = @fill_color = @line_color = 0
      @line_height = 1.7
      @auto_path = true
      start_misc
    end

    def close
      end_text if @in_text
      end_graph if @in_graph
      end_misc if @in_misc
      pdf_stream = PdfStream.new(@doc.next_seq, 0, @stream)
      @doc.file.body << pdf_stream
      @page.annots = @annotations if @annotations.size.nonzero?
      @page.contents << pdf_stream
      @doc.catalog.pages.kids << @page
      @stream = nil
    end

    def closed?
      @stream.nil?
    end

    # coordinate methods
    def units=(units)
      @loc = convert_units(@loc, @units, units)
      @last_loc = convert_units(@last_loc, @units, units)
      @units = units
    end

    def page_width
      from_points(@units, @page_width)
    end

    def page_height
      from_points(@units, @page_height)
    end

    def move_to(x, y)
      @loc = Location.new(x, page_height - y)
    end

    def pen_pos
    end

    # graphics methods
    def line_to(x, y)
      start_graph unless @in_graph
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
    end

    def rectangle(x, y, width, height, options={})
      border = options[:border].nil? ? true : options[:border]
      fill = options[:fill].nil? ? false : options[:fill]
      start_graph unless @in_graph
      gw.stroke if @in_path and @auto_path

      push_line_color(border)
      push_fill_color(fill)
      check_set(:line_color, :line_width, :line_dash_pattern, :fill_color)

      if options[:corners]
        draw_rounded_rectangle(x, y, width, height, options)
      elsif options[:path]
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
      else
        gw.rectangle(
            to_points(@units, x),
            @page_height - to_points(@units, y + height),
            to_points(@units, width),
            to_points(@units, height))
      end

      auto_stroke_and_fill(:stroke => border, :fill => fill)
      pop_line_color
      pop_fill_color
      move_to(x + width, y)
    end

    def curve(x0, y0, x1, y1, x2, y2, x3, y3)
      start_graph unless @in_graph

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
      start_graph unless @in_graph
      move_to(points[0].x, points[0].y)
      unless @last_loc == @loc
        if @in_path and @auto_path
          gw.stroke
          @in_path = false
        end
      end

      check_set(:line_color, :line_width, :line_dash_pattern)

      gw.move_to(to_points(@units, @loc.x), to_points(@units, @loc.y)) unless @loc == @last_loc # @in_path
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

    def curve_to(points)
    end

    def points_for_circle(x, y, r)
      points = (1..4).inject([]) { |points, q| points + get_quadrant_bezier_points(q, x, y, r) }
      [12,8,4].each { |i| points.delete_at(i) }
      points
    end

    def circle(x, y, r, options={})
      border = options[:border].nil? ? true : options[:border]
      fill = options[:fill].nil? ? false : options[:fill]

      push_line_color(border)
      push_fill_color(fill)
      check_set(:line_color, :line_width, :line_dash_pattern, :fill_color)

      points = points_for_circle(x, y, r)
      points.reverse! if options[:reverse]
      curve_points(points)

      auto_stroke_and_fill(:stroke => border, :fill => fill)
      pop_line_color
      pop_fill_color
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

      push_line_color(border)
      push_fill_color(fill)
      check_set(:line_color, :line_width, :line_dash_pattern, :fill_color)

      points = points_for_ellipse(x, y, rx, ry)
      points = rotate_points(Location.new(x, y), points, -rotation)
      points.reverse! if options[:reverse]
      curve_points(points)

      auto_stroke_and_fill(:stroke => border, :fill => fill)
      pop_line_color
      pop_fill_color
    end

    def points_for_arc(x, y, r, start_angle, end_angle)
      return nil if start_angle == end_angle

      num_arcs = 1
      ccwcw = 1.0
      arc_span = end_angle - start_angle
      if end_angle < start_angle
        ccwcw = -1.0
      end
      while arc_span.abs / num_arcs.to_f > 90.0
        num_arcs += 1
      end
      angle_bump = arc_span / num_arcs.to_f
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
      while arc_span.abs / num_arcs.to_f > 90.0
        num_arcs += 1
      end
      angle_bump = arc_span / num_arcs.to_f
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
      start_graph unless @in_graph
      unless @last_loc == @loc
        gw.stroke if @in_path and @auto_path
        @in_path = false
      end

      push_line_color(border)
      push_fill_color(fill)
      check_set(:line_color, :line_width, :line_dash_pattern, :fill_color)

      move_to(x, y)
      gw.move_to(to_points(@units, @loc.x), to_points(@units, @loc.y))
      @last_loc = @loc.clone
      @in_path = true
      start_angle, end_angle = end_angle, start_angle if options[:reverse]
      arc(x, y, r, start_angle, end_angle)
      line_to(x, y)

      auto_stroke_and_fill(:stroke => border, :fill => fill)
      pop_line_color
      pop_fill_color
    end

    def arch(x, y, r1, r2, start_angle, end_angle, options={})
      return if start_angle == end_angle
      start_angle, end_angle = end_angle, start_angle if options[:reverse]
      border = options[:border].nil? ? true : options[:border]
      fill = options[:fill].nil? ? false : options[:fill]
      start_graph unless @in_graph
      unless @last_loc == @loc
        gw.stroke if @in_path and @auto_path
        @in_path = false
      end

      push_line_color(border)
      push_fill_color(fill)
      check_set(:fill_color)
      arc1 = points_for_arc(x, y, r1, start_angle, end_angle)
      arc2 = points_for_arc(x, y, r2, end_angle, start_angle)
      move_to(arc1.first.x, arc1.first.y)
      gw.move_to(to_points(@units, @loc.x), to_points(@units, @loc.y))
      curve_points(arc1)
      line_to(arc2.first.x, arc2.first.y)
      curve_points(arc2)
      line_to(arc1.first.x, arc1.first.y)
      
      auto_stroke_and_fill(:stroke => border, :fill => fill)
      pop_line_color
      pop_fill_color
    end

    def points_for_polygon(x, y, r, sides, options={})
      step = 360.0 / sides
      angle = step / 2 + 90
      points = (0..sides).collect do
        px, py = rotate_xy_coordinate(r, 0, angle)
        angle += step
        Location.new(x + px * r, y + py * r)
      end
      rotation = options[:rotation] || 0
      points = rotate_points(Location.new(x, y), points, -rotation) unless rotation.zero?
      points.reverse! if options[:reverse]
      points
    end

    def polygon(x, y, r, sides, options={})
      border = options[:border].nil? ? true : options[:border]
      fill = options[:fill].nil? ? false : options[:fill]
      start_graph unless @in_graph
      unless @last_loc == @loc
        gw.stroke if @in_path and @auto_path
        @in_path = false
      end

      points = points_for_polygon(x, y, r, sides, options)
      push_line_color(border)
      push_fill_color(fill)
      check_set(:line_color, :line_width, :line_dash_pattern, :fill_color)

      points.each_with_index do |point, i|
        if i == 0
          move_to(point.x, point.y)
        else
          line_to(point.x, point.y)
        end
      end
      auto_stroke_and_fill(:stroke => border, :fill => fill)
      pop_line_color
      pop_fill_color
    end

    def star(x, y, r, points, options={})
      return if points < 5
      border = options[:border].nil? ? true : options[:border]
      fill = options[:fill].nil? ? false : options[:fill]
      start_graph unless @in_graph
      unless @last_loc == @loc
        gw.stroke if @in_path and @auto_path
        @in_path = false
      end

      rotation = options[:rotation] || 0
      r2 = (points - 2).to_f / points.to_f
      vertices1 = points_for_polygon(x, y, r, points, options)
      vertices2 = points_for_polygon(x, y, r2, points, options.merge(:rotation => rotation + (360.0 / points / 2)))
      push_line_color(border)
      push_fill_color(fill)
      check_set(:line_color, :line_width, :line_dash_pattern, :fill_color)

      move_to(vertices2[0].x, vertices2[0].y)
      points.times do |i|
        line_to(vertices1[i].x, vertices1[i].y)
        line_to(vertices2[i+1].x, vertices2[i+1].y)
      end
      auto_stroke_and_fill(:stroke => border, :fill => fill)
      pop_line_color
      pop_fill_color
    end

    def path(options={})
      @auto_path = false
      if block_given?
        yield
        if options[:fill] and options[:stroke]
          gw.fill_and_stroke
        elsif options[:stroke]
          gw.stroke
        elsif options[:fill]
          gw.fill
        end
        @in_path = false
        @auto_path = true
      end
    end

    def fill
      raise Exception.new("Not in graph") unless @in_graph
      raise Exception.new("Not in path") unless @in_path

      check_set(:fill_color)
      gw.fill
      @in_path = false
      @auto_path = true
    end

    def stroke
      raise Exception.new("Not in graph") unless @in_graph
      raise Exception.new("Not in path") unless @in_path

      check_set(:line_color)
      gw.stroke
      @in_path = false
      @auto_path = true
    end

    def fill_and_stroke
      raise Exception.new("Not in graph") unless @in_graph
      raise Exception.new("Not in path") unless @in_path

      check_set(:fill_color,:line_color)
      gw.fill_and_stroke
      @in_path = false
      @auto_path = true
    end

    def line_dash_pattern
      @line_dash_pattern
    end

    def line_dash_pattern=(pattern)
      @line_dash_pattern = case pattern
        when :solid  then '[] 0'
        when :dotted then '[1 2] 0'
        when :dashed then '[4 2] 0'
      else
        pattern.to_s
      end
    end

    def line_width
      from_points(@units, @line_width)
    end

    def line_width=(width)
      if width.respond_to?(:to_str) and width =~ /\D+/
        u, width = $&.to_sym, width.to_f
      else
        u = @units
      end        
      @line_width = to_points(u, width)
    end

    # color methods
    def line_color
      @line_color
    end

    def line_color=(color)
      if color.is_a?(Array)
        r, g, b = color
        @line_color = color_from_rgb(r, g, b)
      else
        @line_color = color
      end        
    end

    def set_fill_color_rgb(red, green, blue)
    end

    def fill_color(color)
      @fill_color
    end

    def fill_color=(color)
      if color.is_a?(Array)
        r, g, b = color
        @fill_color = color_from_rgb(r, g, b)
      else
        @fill_color = color
      end        
    end

    def font_color
      @font_color
    end

    def font_color=(color)
      if color.is_a?(Array)
        r, g, b = color
        @font_color = color_from_rgb(r, g, b)
      else
        @font_color = color
      end        
    end

    # text methods
    def print(text, options={})
      return if text.empty?
      angle = options[:angle] || 0.0
      raise Exception.new("No font set.") unless @font
      start_text unless @in_text
      if (@text_angle != angle) or (angle != 0.0)
        set_text_angle(angle, @loc.x, @loc.y)
      elsif @loc != @last_loc
        @tw.move_by(to_points(@units, @loc.x - @last_loc.x), to_points(@units, @loc.y - @last_loc.y))
      end
      check_set_font
      check_set_font_color
      check_set_v_text_align

      @tw.show(text)
      @last_loc = @loc.clone
      if angle == 0.0
        @loc.x += width(text)
      else
        ds = width(text)
        rad_angle = radians_from_degrees(angle)
        @loc.y += Math::sin(rad_angle) * ds
        @loc.x += Math::cos(rad_angle) * ds
      end
    end

    def print_xy(x, y, text, options={})
      move_to(x, y)
      print(text, options)
    end

    def puts(text='')
      # if it's not a real string, assume it's an enumeration of strings
      unless text.respond_to?(:to_str)
        text.each { |t| puts(t) }
      else
        save_loc = @loc.clone
        print(text)
        @loc = Location.new(save_loc.x, save_loc.y - height * @line_height)
      end
    end

    def puts_xy(x, y, text)
    end

    def width(text)
      result = 0.0
      fsize = @font.size * 0.001
      text.each_byte { |b| result += fsize * @font.widths[b] + @char_spacing; result += @word_spacing if b == 32 }
      from_points(@units, result - @char_spacing)
    end

    def height # may not include external leading?
      0.001 * @font.height * @font.size / UNIT_CONVERSION[@units].to_f
    end

    # font methods
    def set_font(name, size, options = {})
      @font = Font.new
      @font.name = name
      @font.size = size
      @font.style = options[:style] || ''
      @font.color = options[:color]
      @font.encoding = options[:encoding] || 'WinAnsiEncoding'
      @font.sub_type = options[:sub_type] || 'Type1'
      punc = (@font.sub_type == 'TrueType') ? ',' : '-'
      full_name = name.gsub(' ','')
      full_name << punc << @font.style unless @font.style.empty?
      font_key = "#{full_name}/#{@font.encoding}-#{@font.sub_type}"
      @page_font = @doc.fonts[font_key]
      if @font.sub_type == 'Type1'
        metrics = PdfK::font_metrics(full_name)
        @font.widths = metrics.widths
        @font.ascent = metrics.ascent
        @font.descent = metrics.descent
        @font.height = @font.ascent + @font.descent.abs
      else
        raise Exception.new("Unsupported subtype #{@font.sub_type}.")
      end
      unless @page_font
        widths = nil
        if metrics.needs_descriptor
          descriptor = PdfFontDescriptor.new(@doc.next_seq, 0, full_name, metrics.flags, metrics.b_box, 
            metrics.missing_width, metrics.stem_v, metrics.stem_h, metrics.italic_angle,
            metrics.cap_height, metrics.x_height, metrics.ascent, metrics.descent, metrics.leading,
            metrics.max_width, metrics.avg_width)
          @doc.file.body << descriptor
          widths = IndirectObject.new(@doc.next_seq, 0, PdfInteger.ary(metrics.widths))
          @doc.file.body << widths
        else
          descriptor = nil
          widths = nil
        end
        @page_font = "F#{@doc.fonts.size}"
        f = PdfFont.new(@doc.next_seq, 0, @font.sub_type, full_name, 0, 255, widths, descriptor)
        @doc.file.body << f
        if PdfFont.standard_encoding?(@font.encoding)
          f.encoding = @font.encoding
        else
          raise Exception.new("Unsupported encoding #{@font.encoding}")
        end
        @doc.resources.fonts[@page_font] = f.reference_object
        @doc.fonts[font_key] = @page_font
      end
    end

    def set_font_style(style)
    end

    def set_font_size(size)
    end

    # image methods
    def load_image(image_file_name)
    end

    def print_image_handle(pdf_image_handle, x, y, width=nil, height=nil)
    end

    def print_image_file(image_file_name, x, y, width=nil, height=nil)
    end

    def print_link(s, uri)
    end
  end

  class PdfDocumentWriter
    def next_seq
      @next_seq += 1
    end

    attr_reader :cur_page, :pages
    attr_reader :catalog, :file, :resources
    attr_reader :fonts, :images, :encodings
    attr_reader :in_page

    # instantiation
    def initialize
      @fonts = {}
      @images = {}
      @encodings = {}
    end

    def open(options={})
    end

    def close
    end

    def to_s
      @file.to_s
    end

    # document methods
    def begin_doc(options={})
      raise Exception.new("Already in document") if @in_doc
      @in_doc = true
      @options = options
      @pages = []
      @next_seq = 0
      @file = PdfFile.new
      pages = PdfPages.new(next_seq, 0)
      outlines = PdfOutlines.new(next_seq, 0)
      @catalog = PdfCatalog.new(next_seq, 0, :use_none, pages, outlines)
      @file.body << pages << outlines << @catalog
      @file.trailer.root = @catalog
      define_resources
    end

    def end_doc
      end_page if @in_page
      @pages.each { |page| page.close unless page.closed? }
    end
    
    def doc(options={})
      begin_doc(options)
      yield(self)
      end_doc
    end

    # page methods
    def start_page(options={})
      raise Exception.new("Already in page") if @in_page
      @cur_page = PdfPageWriter.new(self, @options.clone.update(options))
      # move_to(0, 0)
      @pages << @cur_page
      @in_page = true
      return @cur_page
    end

    def end_page
      raise Exception.new("Not in page") unless @in_page
      @cur_page.close
      @cur_page = nil
      @in_page = false
    end
    
    def page(options={})
      cur_page = start_page(options)
      yield(cur_page)
      end_page
    end

    def new_page(options={})
      end_page
      start_page(options)
    end
    
    # coordinate methods
    def units
      cur_page.units
    end

    def units=(units)
      cur_page.units=(units)
    end
    
    def line_height
      cur_page.line_height
    end

    def line_height=(height)
      cur_page.line_height = height
    end

    def move_to(x, y)
      cur_page.move_to(x, y)
    end

    def pen_pos
      cur_page.pen_pos
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

    def curve_to(points)
      cur_page.curve_to(points)
    end

    def circle(x, y, r, options={})
      cur_page.circle(x, y, r, options)
    end

    def ellipse(x, y, rx, ry, options={})
      cur_page.ellipse(x, y, rx, ry, options)
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

    def line_dash_pattern
      cur_page.line_dash_pattern
    end

    def line_dash_pattern=(pattern)
      cur_page.line_dash_pattern = pattern
    end

    def line_width
      cur_page.line_width
    end

    def line_width=(width)
      cur_page.line_width = width
    end

    # color methods
    def line_color
      cur_page.line_color
    end

    def line_color=(color)
      cur_page.line_color = color
    end

    def set_fill_color_rgb(red, green, blue)
      cur_page.set_fill_color_rgb(red, green, blue)
    end

    def fill_color
      cur_page.fill_color
    end

    def fill_color=(color)
      cur_page.fill_color = color
    end

    def set_font_color_rgb(red, green, blue)
      cur_page.set_font_color_rgb(red, green, blue)
    end

    def font_color
      cur_page.font_color
    end

    def font_color=(color)
      cur_page.font_color = color
    end

    # text methods
    def print(text, options={})
      cur_page.print(text, options)
    end

    def print_xy(x, y, text, options={})
      cur_page.print_xy(x, y, text, options)
    end

    def puts(text='')
      cur_page.puts(text)
    end

    def puts_xy(x, y, text)
      cur_page.puts_xy(x, y, text)
    end

    def width(text)
      cur_page.width(text)
    end

    def height # may not include external leading?
      cur_page.height
    end

    def v_text_align
      cur_page.v_text_align
    end

    def v_text_align=(vta)
      cur_page.v_text_align = vta
    end

    # font methods
    def set_font(name, size, options = {})
      cur_page.set_font(name, size, options)
    end

    def set_font_style(style)
      cur_page.set_font_style(style)
    end

    def set_font_size(size)
      cur_page.set_font_size(size)
    end

    # image methods
    def load_image(image_file_name)
      cur_page.load_image(image_file_name)
    end

    def print_image_handle(pdf_image_handle, x, y, width=nil, height=nil)
      cur_page.print_image_handle(pdf_image_handle, x, y, width, height)
    end

    def print_image_file(image_file_name, x, y, width=nil, height=nil)
      cur_page.print_image_file(image_file_name, x, y, width, height)
    end

    def print_link(s, uri)
      cur_page.print_link(s, uri)
    end

  protected
    def define_resources
      @resources = PdfResources.new(next_seq, 0)
      @resources.proc_set = PdfName.ary ['PDF','Text','ImageB','ImageC']
      @file.body << @resources
    end

    def make_font_descriptor(font_name)
    end
  end
end
