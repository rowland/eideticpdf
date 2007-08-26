#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-07-13.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

require 'pdfu'

module PdfW
  def f(value, prec=2)
    sprintf("%.*f", prec, value).sub(',','.')
  end

  def g(value, prec=4)
    # prec must be >= 1 or gsub will strip significant trailing 0's.
    sprintf("%.*f", prec, value).sub(',','.').gsub(/\.?0*$/,'')
  end

  class PageStyle
    attr_reader :page_size, :crop_size, :orientation, :landscape
    
    PORTRAIT = 0
    LANDSCAPE = 270

    def initialize(options={})
      page_size = options[:page_size] || :letter
      crop_size = options[:crop_size] || page_size
      @orientation = options[:orientation] || :portrait
      @page_size = make_size_rectangle(page_size, @orientation)
      @crop_size = make_size_rectangle(crop_size, @orientation)
      @landscape = (@orientation == :landscape)
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
      @stream << "%s Ts" % g(rise)
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

  class PdfWriter
  private
    def arc_small(x, y, r, mid_theta, half_angle, ccwcw, move_to0)
    end

    def set_text_angle(angle, x, y)
    end

  protected
    def next_object_number
    end

    def define_resources
    end

    def make_font_descriptor(font_name)
    end

    def check_set_line_dash_pattern
    end

    def check_set_line_width
    end

    # color methods
    def check_set_line_color
    end

    def check_set_fill_color
    end

    def check_set_font_color
    end

  protected
    def start_text
    end

    def end_text
    end

    def start_graph
    end

    def end_graph
    end

    def start_misc
    end

    def end_misc
    end
    
    attr_reader :tw, :gw

    def page_width
    end

    def page_height
    end

  public
    # currently, should only be called once
    def write(stream)
    end

    # document methods
    def begin_doc(options={})
    end

    def end_doc
    end

    # page methods
    def start_page(options={})
    end

    def end_page
    end

    def new_page(options={})
    end

    # coordinate methods
    def units
    end

    def units=(units)
    end

    def moveTo(x, y)
    end

    def pen_pos
    end

    # graphics methods
    def line_to(x, y)
    end

    def rectangle(x, y, width, height, border=true, fill=false)
    end

    def curve(x0, y0, x1, y1, x2, y2, x3, y3)
    end

    def curve_points(points)
    end

    def curve_to(points)
    end

    def circle(x, y, r, border=true, fill=false)
    end

    def arc(x, y, r, s_angle, e_angle, move_to0=false)
    end

    def pie(x, y, r, s_angle, e_angle, border=true, fill=false)
    end

    def arch(x, y, r1, r2, s_angle, e_angle, border=true, fill=false)
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
    def print(s, angle=0.0)
    end

    def print_xy(x, y, s, angle=0.0); overload
    end

    def puts(s='')
    end

    def puts_xy(x, y, s)
    end

    def width(s)
    end

    def height # may not include external leading?
    end

    def set_v_text_align(vta)
    end

    # font methods
    def set_font(
        name,
        size,
        style='',
        color=nil, # nil means don't set color
        encoding='WinAnsiEncoding',
        sub_type='Type1')
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

    # instantiation
    def initialize
    end
    
    def open
    end
    
    def close
    end
  end
end
