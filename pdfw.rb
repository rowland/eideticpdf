#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-07-13.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

require 'pdfu'
require 'pdfk'

module PdfW
  UNIT_CONVERSION = { :pt => 1, :in => 72, :cm => 28.35 }

  Location = Struct.new(:x, :y)

  def to_points(units, measurement)
    UNIT_CONVERSION[units] * measurement
  end

  def convert_units(loc, from_units, to_units)
    Location.new(
      loc.x * UNIT_CONVERSION[from_units] / UNIT_CONVERSION[to_units],
      loc.y * UNIT_CONVERSION[from_units] / UNIT_CONVERSION[to_units])
  end

  Signs = Struct.new(:x, :y)

  SIGNS = [ Signs.new(1, -1), Signs.new(-1, -1), Signs.new(-1, 1), Signs.new(1, 1) ]

  def get_quadrant_bezier_points(quadrant, x, y, r)
    a = 4.0 / 3.0 * (Math.sqrt(2) - 1.0)
    bp = []
    if (quadrant % 2 == 1) # quadrant is odd
      # (1,0)
      bp << Location.new(x + (r * SIGNS[quadrant - 1].x), y)
      # (1,a)
      bp << Location.new(bp[0].x, y + (a * r * SIGNS[quadrant - 1].y))
      # (a,1)
      bp << Location.new(x + (a * r * SIGNS[quadrant - 1].x), y + (r * SIGNS[quadrant - 1].y))
      # (0,1)
      bp << Location.new(x, bp[2].y)
    else # quadrant is even
      # (0,1)
      bp << Location.new(x, y + (r * SIGNS[quadrant - 1].y))
      # (a,1)
      bp << Location.new(x + (a * r * SIGNS[quadrant - 1].x), bp[0].y)
      # (1,a)
      bp << Location.new(x + (r * SIGNS[quadrant - 1].x), y + (a * r * SIGNS[quadrant - 1].y))
      # (1,0)
      bp << Location.new(bp[2].x, y)
    end
    bp
  end

  def f(value, prec=2)
    sprintf("%.*f", prec, value).sub(',','.')
  end

  def g(value, prec=4)
    # prec must be >= 1 or gsub will strip significant trailing 0's.
    sprintf("%.*f", prec, value).sub(',','.').gsub(/\.?0*$/,'')
  end
  
  def radians_from_degrees(degrees)
    degrees * Math::PI / 180.0
  end

  Font = Struct.new(:name, :size, :style, :color, :encoding, :sub_type, :widths, :ascent, :descent, :height)

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
      @rotate = ROTATIONS[@orientation]
    end

  private
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
        :portrait => [0,0,499,70].freeze,
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
      PdfU::Rectangle.new(*(SIZES[size][orientation]))
    end
  end

  class MiscWriter
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

  class GraphWriter
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

  class TextWriter
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
      @stream << "(%s) Tj\n" % PdfU::PdfString.escape(s)
    end

    def next_line_show(s)
      @stream << "(%s) '" % PdfU::PdfString.escape(s)
    end

    def set_spacing_next_line_show(char_space, word_space, s)
      @stream << "%s %s (%s) \"\n" % [g(char_space), g(word_space), PdfU::PdfString.escape(s)]
    end

    def show_with_dispacements(elements)
      @stream << "%sTJ\n" % elements
    end
  end

  class PdfPageWriter
  private
    def arc_small(x, y, r, mid_theta, half_angle, ccwcw, move_to0)
    end

    def set_text_angle(angle, x, y)
      theta = radians_from_degrees(angle)
      v_cos = Math::cos(theta)
      v_sin = Math::sin(theta)
      @tw.set_matrix(v_cos, v_sin, -v_sin, v_cos, to_points(@units, x), to_points(@units, y))
      @text_angle = angle
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
        @gw.stroke
        @in_path = false
      end
      @gw = nil
      @in_graph = false
    end

    def start_misc
    end

    def end_misc
    end

    attr_reader :tw, :gw

    def page_width
      @page_width / UNIT_CONVERSION[@units]
    end

    def page_height
      @page_height / UNIT_CONVERSION[@units]
    end

    # color methods
    def check_set_line_color
    end

    def check_set_v_text_align(force=false)
      if force or @last_v_text_align != @v_text_align
        if @v_text_align == :top
          @tw.set_rise(-@font.height * 0.001 * @font.size)
        else
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
    end

    def check_set_font_color
    end

    def check_set_line_dash_pattern
    end

    def check_set_line_width
    end

  public
    attr_reader :doc, :units
    attr_reader :stream, :annotations
    attr_accessor :v_text_align

    def initialize(doc, options)
      # doc: PdfDocumentWriter
      @doc = doc
      @page_style = PageStyle.new(options)
      @loc = Location.new(0, 0)
      @units = options[:units] || :pt
      @page_width = @page_style.page_size.x2
      @page_height = @page_style.page_size.y2
      @page = PdfU::PdfPage.new(@doc.next_seq, 0, @doc.catalog.pages)
      @page.media_box = @page_style.page_size.clone
      @page.crop_box = @page_style.crop_size.clone
      @page.rotate = @page_style.rotate
      @page.resources = @doc.resources
      @doc.file.body << @page
      @stream = ''
      @annotations = []
      @char_spacing = @word_spacing = 0.0
      start_misc
    end

    def close
      end_text if @in_text
      end_graph if @in_graph
      end_misc if @in_misc
      pdf_stream = PdfU::PdfStream.new(@doc.next_seq, 0, @stream)
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

    def move_to(x, y)
      @loc = Location.new(x, page_height - y)
    end

    def pen_pos
    end

    # graphics methods
    def line_to(x, y)
      start_graph unless @in_graph
      unless @last_loc != @loc
        @gw.stroke if @in_path
        @in_path = false
      end

      check_set_line_color
      check_set_line_width
      check_set_line_dash_pattern
      
      @gw.move_to(to_points(@units, @loc.x), to_points(@units, @loc.y)) unless @in_path
      move_to(x, y)
      @gw.line_to(to_points(@units, @loc.x), to_points(@units, @loc.y))
      @in_path = true
      @last_loc = @loc
    end

    def rectangle(x, y, width, height, border=true, fill=false)
      start_graph unless @in_graph
      @gw.stroke if @in_path

      check_set_line_color
      check_set_line_width
      check_set_line_dash_pattern
      check_set_fill_color
      
      @gw.rectangle(
          to_points(@units, x),
          @page_height - to_points(@units, y + height),
          to_points(@units, width),
          to_points(@units, height))

      if (border and fill)
        @gw.fill_and_stroke
      elsif border then
        @gw.stroke
      elsif fill then
        @gw.fill
      end

      @in_path = false
      move_to(x + width, y)
    end

    def curve(x0, y0, x1, y1, x2, y2, x3, y3)
    end

    def curve_points(points)
      raise Exception.new("Need at least 4 points for curve") if points.size < 4
      start_graph unless @in_graph
      move_to(points[0].x, points[0].y)
      unless @last_loc == @loc
        if @in_path
          @gw.stroke
          @in_path = false
        end
      end
      
      check_set_line_color
      check_set_line_width
      check_set_line_dash_pattern
      
      @gw.move_to(to_points(@units, @loc.x), to_points(@units, @loc.y)) unless @in_path
      i = 1
      while i + 2 < points.size
        @gw.curve_to(
          to_points(@units, points[i].x),
          @page_height - to_points(@units, points[i].y),
          to_points(@units, points[i+1].x),
          @page_height - to_points(@units, points[i+1].y),
          to_points(@units, points[i+2].x),
          @page_height - to_points(@units, points[i+2].y)
        )
        move_to(points[i+2].x, points[i+2].y)
        @last_loc = @loc
        i += 3
      end
      @in_path = true
    end

    def curve_to(points)
    end

    def circle(x, y, r, border=true, fill=false)
      1.upto(4) do |q|
        bp = get_quadrant_bezier_points(q,x,y,r)
        curve_points(bp)
      end
      check_set_fill_color
      if (border and fill)
        @gw.fill_and_stroke
      elsif border
        @gw.stroke
      elsif fill
        @gw.fill
      end

      @in_path = false
    end

    def arc(x, y, r, start_angle, end_angle, move_to0=false)
    end

    def pie(x, y, r, start_angle, end_angle, border=true, fill=false)
    end

    def arch(x, y, r1, r2, start_angle, end_angle, border=true, fill=false)
    end

    def fill
    end

    def stroke
    end

    def fill_and_stroke
    end

    def set_line_dash_pattern(pattern, phase)
    end

    def set_line_width(line_width)
    end

    # color methods
    def set_line_color_rgb(red, green, blue)
    end

    def set_line_color(color)
    end

    def set_fill_color_rgb(red, green, blue)
    end

    def set_fill_color(color)
    end

    def set_font_color_rgb(red, green, blue)
    end

    def set_font_color(color)
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
      @last_loc = @loc
      if angle == 0.0
        @loc.x += width(text)
      else
        ds = width(s)
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
    end

    def puts_xy(x, y, text)
    end

    def width(text)
      result = 0.0
      fsize = @font.size * 0.001
      text.each_byte { |b| result += fsize * @font.widths[b] + @char_spacing; result += @word_spacing if b == 32 }
      (result - @char_spacing) / UNIT_CONVERSION[@units]
    end

    def height # may not include external leading?
    end

    def set_v_text_align(vta)
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
        descriptor = nil
        @page_font = "F#{@doc.fonts.size}"
        f = PdfU::PdfFont.new(@doc.next_seq, 0, @font.sub_type, full_name, 0, 255, widths, descriptor)
        @doc.file.body << f
        if PdfU::PdfFont.standard_encoding?(@font.encoding)
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
      @file = PdfU::PdfFile.new
      pages = PdfU::PdfPages.new(next_seq, 0)
      outlines = PdfU::PdfOutlines.new(next_seq, 0)
      @catalog = PdfU::PdfCatalog.new(next_seq, 0, :use_none, pages, outlines)
      @file.body << pages << outlines << @catalog
      @file.trailer.root = @catalog
      define_resources
    end

    def end_doc
      @pages.each { |page| page.close unless page.closed? }
    end

    # page methods
    def start_page(options={})
      raise Exception.new("Already in page") if @in_page
      @cur_page = PdfPageWriter.new(self, @options.clone.update(options))
      @pages << @cur_page
      @in_page = true
    end

    def end_page
      raise Exception.new("Not in page") unless @in_page
      @cur_page.close
      @cur_page = nil
      @in_page = false
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

    def rectangle(x, y, width, height, border=true, fill=false)
      cur_page.rectangle(x, y, width, height, border, fill)
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

    def circle(x, y, r, border=true, fill=false)
      cur_page.circle(x, y, r, border, fill)
    end

    def arc(x, y, r, start_angle, end_angle, move_to0=false)
      cur_page.arc(x, y, r, start_angle, end_angle, move_to0)
    end

    def pie(x, y, r, start_angle, end_angle, border=true, fill=false)
      cur_page.pie(x, y, r, start_angle, end_angle, border, fill)
    end

    def arch(x, y, r1, r2, start_angle, end_angle, border=true, fill=false)
      cur_page.arch(x, y, r1, r2, start_angle, end_angle, border, fill)
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

    def set_line_dash_pattern(pattern, phase)
      cur_page.set_line_dash_pattern(pattern, phase)
    end

    def set_line_width(line_width)
      cur_page.set_line_width(line_width)
    end

    # color methods
    def set_line_color_rgb(red, green, blue)
      cur_page.set_line_color_rgb(red, green, blue)
    end

    def set_line_color(color)
      cur_page.set_line_color(color)
    end

    def set_fill_color_rgb(red, green, blue)
      cur_page.set_fill_color_rgb(red, green, blue)
    end

    def set_fill_color(color)
      cur_page.set_fill_color(color)
    end

    def set_font_color_rgb(red, green, blue)
      cur_page.set_font_color_rgb(red, green, blue)
    end

    def set_font_color(color)
      cur_page.set_font_color(color)
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

    def set_v_text_align(vta)
      cur_page.set_v_text_align(vta)
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
      @resources = PdfU::PdfResources.new(next_seq, 0)
      @resources.proc_set = PdfU::PdfName.ary ['PDF','Text','ImageB','ImageC']
      @file.body << @resources
    end

    def make_font_descriptor(font_name)
    end
  end
end
