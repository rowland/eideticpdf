#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-07-13.
#  Copyright (c) 2007, 2008 Eidetic Software. All rights reserved.

require 'epdfpw'
require 'epdfo'
require 'epdfk'
require 'epdfafm'
require 'epdftt'

module EideticPDF

  class DocumentWriter
    def next_seq
      @next_seq += 1
    end

    attr_reader :pages
    attr_reader :catalog, :file, :resources
    attr_reader :fonts, :images, :encodings, :bullets
    attr_reader :in_page

    # instantiation
    def initialize
      @fonts = {}
      @images = {}
      @encodings = {}
      @bullets = {}
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

    def indent(value=nil, absolute=false)
      cur_page.indent(value, absolute)
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

    def text_height(units=nil)
      cur_page.text_height(units)
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

    def underline(underline=nil)
      cur_page.underline(underline)
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

    def bullet(name, options={}, &block)
      cur_page.bullet(name, options, &block)
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
