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
    def next_seq # :nodoc:
      @next_seq += 1
    end

    attr_reader :pages # :nodoc:
    attr_reader :catalog, :file, :resources # :nodoc:
    attr_reader :fonts, :images, :encodings, :bullets # :nodoc:
    attr_reader :in_page

    # Instantiate a new DocumentWriter object.  Document is NOT open for writing at this point.
    def initialize
      @fonts = {}
      @images = {}
      @encodings = {}
      @bullets = {}
    end

    def to_s
      @file.to_s
    end

    # Open the document for writing.
    #
    # The following document options apply:
    # [:+pages_up+] A tuple of the form [+pages_across+, +pages_down+] specifying the layout of virtual pages.  Defaults to [1, 1] (no virtual pages).
    # [:+pages_up_layout+] When :+across+, virtual pages proceed from left to right before top to bottom.  When :+down+, virtual pages proceed from top to bottom before left to right.
    #
    # In addition, any of the options for +open_page+ may be supplied and will apply to each page, unless explicitly overridden.
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

    # Close any open pages, preparing the document for rendering to PDF.
    def close
      open_page if @pages.empty? # empty document needs at least one page
      close_page if @in_page
      @pages.each { |page| page.close unless page.closed? }
    end

    # Open the document for writing and yield to the block given before calling +close+.
    def doc(options={}, &block)
      open(options)
      yield(self)
      close
    end

    # Open a page for writing.  Raises Exception if a page is already open.
    #
    # The following page options apply:
    # [:+compress+] Compress page streams using zlib deflate.
    # [:+units+] A symbol from EideticPDF::UNIT_CONVERSION hash, specifying ratio of units to points.  Defaults to :+pt+.  Other choices are :+in+ for inches and :+cm+ for centimeters.  Custom units may be added.
    # [:+v_text_align+] Initial vertical text alignment for page.  See +v_text_align+ method.
    # [:+font+] Initial font for page.  Defaults to <tt>{ :name => 'Helvetica', :size => 12 }</tt>.
    # [:+fill_color+] Initial fill color.  Defaults to 0 (black).  See +fill_color+ method.
    # [:+line_color+] Initial line color.  Defaults to 0 (black).  See +line_color+ method.
    # [:+line_height+] Initial line height.  Defaults to 1.7.  See +line_height+ method.
    # [:+line_width+] Initial line width.  Defaults to 1.0.  See +line_width+ method.
    # [:+margins+] Page margins.  Defaults to 0.  See +margins+ method.
    # [:+unscaled+] If true, virtual pages are not scaled down.  Defaults to +false+.
    def open_page(options={})
      raise Exception.new("Already in page") if @in_page
      options.update(:_page => pdf_page(@pages.size), :sub_page => sub_page(@pages.size))
      @cur_page = PageWriter.new(self, @options.merge(options))
      @pages << @cur_page
      @in_page = true
      return @cur_page
    end

    # Close the current open page.  Raises Exception if no page is currently open.
    def close_page
      raise Exception.new("Not in page") unless @in_page
      @cur_page.close
      @cur_page = nil
      @in_page = false
    end

    # Open a page for writing and yield to the block given before calling +close_page+.
    #
    # +options+ is passed through to +open_page+.
    def page(options={}, &block)
      cur_page = open_page(options)
      yield(cur_page)
      close_page
    end

    def new_page(options={})
      close_page
      open_page(options)
    end

    def cur_page # :nodoc:
      @cur_page || open_page
    end

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

    # +page_height+ excluding top and bottom margins.
    def canvas_width
      cur_page.canvas_width
    end

    # +page_width+ excluding left and right margins.
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

    def line_to(x, y)
      cur_page.line_to(x, y)
    end

    def line(x, y, angle, length)
      cur_page.line(x, y, angle, length)
    end

    def rectangle(x, y, width, height, options={})
      cur_page.rectangle(x, y, width, height, options)
    end

    # Draw a cubic Bezier curve from <tt>(x0, y0)</tt> to <tt>(x3, y3)</tt> with control points <tt><x1, y1></tt> and <tt>(x2, y2)</tt>.
    # If the first point does not coincide with the current position, any current path is stroked and a new path is begun.
    # Otherwise, the curve is appended to the current path.
    def curve(x0, y0, x1, y1, x2, y2, x3, y3)
      cur_page.curve(x0, y0, x1, y1, x2, y2, x3, y3)
    end

    # Draw a series of cubic Bezier curves.  After moving to the first point, a curve to the 4th point is appended to the current path
    # with the 2nd and 3rd points acting as control points.  A curve is appended to the current path for each additional group
    # of 3 points, with the 1st and 2nd point in each group acting as control points.
    #
    # [+points+] array of Location structs
    def curve_points(points)
      cur_page.curve_points(points)
    end

    def points_for_circle(x, y, r)
      cur_page.points_for_circle(x, y, r)
    end

    # Draw a circle with origin <tt>x, y</tt> and radius +r+.
    # Direction is counterclockwise (anticlockwise), unless :+reverse+ option is specified.
    #
    # The following +options+ apply:
    # [:+border+] If true or a color, a border is drawn with the current or specified +line_color+, respectively. Defaults to +true+.
    # [:+fill+] If true or a color, the area is filled with the current or specified +fill_color+, respectively. Defaults to +false+.
    # [:+clip+] The shape acts as a clipping boundary for anything drawn within the supplied block.
    # [:+reverse+] Draw circle clockwise.  Useful for drawing hollow shapes.
    def circle(x, y, r, options={}, &block)
      cur_page.circle(x, y, r, options, &block)
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

    # Draw an arc with origin <tt>x, y</tt> and radius +r+ from +start_angle+ to +end_angle+ degrees.
    # Direction is counterclockwise (anticlockwise), unless +end_angle+ < +start_angle+.
    # Angles are allowed to exceed 360 degrees.
    #
    # By default, arc extends the current path to the point where the arc begins.
    # If <tt>move_to0</tt> is true (or there is no current path) a move is performed to where the arc begins.
    #
    # This method returns immediately if <tt>start_angle == end_angle</tt>.
    def arc(x, y, r, start_angle, end_angle, move_to0=false)
      cur_page.arc(x, y, r, start_angle, end_angle, move_to0)
    end

    def pie(x, y, r, start_angle, end_angle, options={})
      cur_page.pie(x, y, r, start_angle, end_angle, options)
    end

    # Draw an arch with origin <tt>x, y</tt> from +start_angle+ to _end_angle_ degrees.
    # The result is a bounded area between radii <tt>r1</tt> and <tt>r2</tt>.
    #
    # The following +options+ apply:
    # [:+border+] If true or a color, a border is drawn with the current or specified +line_color+, respectively. Defaults to +true+.
    # [:+fill+] If true or a color, the area is filled with the current or specified +fill_color+, respectively. Defaults to +false+.
    # [:+clip+] The shape acts as a clipping boundary for anything drawn within the supplied block. Defaults to +true+ if a block is given, otherwise +false+.
    # [:+reverse+] By default, the bounding path is drawn from <tt>(r1, start_angle)</tt> to <tt>(r1, end_angle)</tt>, <tt>(r2, end_angle)</tt>, <tt>(r2, start_angle)</tt> and back to <tt>(r1, start_angle)</tt>.  This order is reversed if <tt>reverse => true</tt>.  This is useful for drawing hollow shapes.
    def arch(x, y, r1, r2, start_angle, end_angle, options={}, &block)
      cur_page.arch(x, y, r1, r2, start_angle, end_angle, options, &block)
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

    # Use current path as a clipping boundary for anything drawn within the supplied block.
    #
    # The following +options+ apply:
    # [:+stroke+] If true, the current path is stroked with the current +line_color+.  Defaults to +false+.
    # [:+fill+] If true, the area bounded by the current path is filled with the current +fill_color+.  Defaults to +false+.
    def clip(options={}, &block)
      cur_page.clip(options, &block)
    end

    def line_dash_pattern(pattern=nil)
      cur_page.line_dash_pattern(pattern)
    end

    def line_width(width=nil, units=nil)
      cur_page.line_width(width, units)
    end

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

    def type1_font_names
      if @options[:built_in_fonts]
        PdfK::FONT_NAMES
      else
        AFM::font_names
      end
    end

    def truetype_font_names # :nodoc:
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

    # Given a block, defines a named bullet.  Otherwise the named Bullet struct is returned.
    #
    # The following +options+ apply:
    # [:+units+] The units that :+width+ is expressed in.  Defaults to the current units setting.
    # [:+width+] The width of the area reserved for the bullet.
    #
    # If a block is given, the block should expect a +writer+ parameter to be used for printing or drawing the bullet.
    # Within the block, all altered settings, other than the location, should be restored.
    def bullet(name, options={}, &block)
      cur_page.bullet(name, options, &block)
    end

  protected
    def define_resources # :nodoc:
      @resources = PdfObjects::PdfResources.new(next_seq, 0)
      @resources.proc_set = PdfObjects::PdfName.ary ['PDF','Text','ImageB','ImageC']
      @file.body << @resources
    end

    def sub_page(page_no) # :nodoc:
      if @pages_up == 1
        nil
      elsif @options[:pages_up_layout] == :down
        [page_no % @pages_down, @pages_across, (page_no / @pages_down) % @pages_across, @pages_down]
      else
        [page_no % @pages_across, @pages_across, (page_no / @pages_across) % @pages_down, @pages_down]
      end
    end

    def pdf_page(page_no) # :nodoc:
      if page = @pages[page_no / @pages_up * @pages_up]
        page.page
      else
        nil
      end
    end
  end
end
