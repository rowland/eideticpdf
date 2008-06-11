#!/usr/bin/env ruby
# encoding: ASCII-8BIT
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

    # Render document to PDF and return as a binary string.
    def to_s
      @file.to_s
    end

    # Open the document for writing.
    #
    # The following document options apply:
    # [:+pages_up+] A tuple (array) of the form [+pages_across+, +pages_down+] specifying the layout of virtual pages.  Defaults to [1, 1] (no virtual pages).
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

    # Close the current page and begin a new page with the specified options.
    # [+options+] See +open_page+ method.
    def new_page(options={})
      close_page
      open_page(options)
    end

    def cur_page # :nodoc:
      @cur_page || open_page
    end

    # Set units measurements are to be specified in.  If no units are specified, returns current units setting.
    # Valid units include :+pt+ (points), :+in+ (inches) and :+cm+ (centimeters) by default.
    #
    # Custom units can be specified by updating the EideticPDF::UNIT_CONVERSION hash with a new symbol and conversion ratio.
    def units(units=nil)
      cur_page.units(units)
    end

    # Set top, right, bottom and left margins.  If 1, 2 or 4 values are not specified, returns current margins as a tuple (array)
    # of values in the form [top, right, bottom, left].
    # [+margins+] When 4 values are given, [top, right, bottom, left].  When 2 values are given, [top and bottom, right and left].  When 1 value is specified, it is used for all 4 settings.
    def margins(*margins)
      cur_page.margins(*margins)
    end

    # Returns top margin as set by +margins+ method.
    def margin_top
      cur_page.margin_top
    end

    # Returns right margin as set by +margins+ method.
    def margin_right
      cur_page.margin_right
    end

    # Returns bottom margin as set by +margins+ method.
    def margin_bottom
      cur_page.margin_bottom
    end

    # Returns left margin as set by +margins+ method.
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

    # Set horizontal tabs using an array of numbers or a comma-delimited string.  If no tabs are specified, returns current tabs.
    # Use false to clear current tab stops.
    def tabs(tabs=nil)
      cur_page.tabs(tabs)
    end

    # Move right to next horizontal tab.  If no more tab stops exist, then moves to first tab stop on the following line.
    # If a block is given, the value returned is used instead as the vertical distance to move down.
    def tab(&block)
      cur_page.tab(&block)
    end

    # Set vertical tabs using an array of numbers or a comma-delimited string.  If no tabs are specified, returns current tabs.
    # Use false to clear current tab stops.
    def vtabs(tabs=nil)
      cur_page.vtabs(tabs)
    end

    # Move down to next vertical tab.  If no more tab stops exist and a block is given, moves up to the first vertical tab stop
    # and right the value returned by the block.
    def vtab(&block)
      cur_page.vtab(&block)
    end

    # Set horizontal indentation.  If no value is specified, returns current indentation setting.
    # [+value+] The new indentation.
    # [+absolute+] If +true+, the new value is relative only to the left margin.  If +false+, value is relative to previous indentation.
    # The indent setting is used by the +puts+ and +new_line+ methods.
    def indent(value=nil, absolute=false)
      cur_page.indent(value, absolute)
    end

    # Returns page width in current units.
    def page_width
      cur_page.page_width
    end

    # Returns page height in current units.
    def page_height
      cur_page.page_height
    end

    # Set line height as used by methods like +paragraph+ that display multiple lines of text.
    # If no value is specified, returns current +line_height+.
    # [+height+] Ratio of +font_size+ to effective line height.
    def line_height(height=nil)
      cur_page.line_height(height)
    end

    # Move pen to point <tt>(x, y)</tt>.
    def move_to(x, y)
      cur_page.move_to(x, y)
    end

    # Move pen to point <tt>(x, y)</tt> like +move_to+, returning previous location.  If x is not specified, returns current location.
    def pen_pos(x=nil, y=nil)
      cur_page.pen_pos(x, y)
    end

    # Move the pen to a new location relative to the current location.
    # [+dx+] Horizontal distance to move pen.  Positive values move right.  Negative values move left.
    # [+dy+] Vertical distance to move pen.  Positive values move down.  Negative values move up.
    def move_by(dx, dy)
      cur_page.move_by(dx, dy)
    end

    # Draw a line from the current location to point <tt>(x, y)</tt>.
    # If +auto_path+ is off, a new segment is appended to the current path.
    def line_to(x, y)
      cur_page.line_to(x, y)
    end

    # Draw a line from point <tt>(x, y)</tt> to a point +length+ units distant at +angle+ degrees.
    def line(x, y, angle, length)
      cur_page.line(x, y, angle, length)
    end

    # Draw a rectangle with the specified +width+ and +height+ and its top, left corner at <tt>(x, y)</tt>.
    #
    # The following +options+ apply:
    # [:+border+] If true or a color, a border is drawn with the current or specified +line_color+, respectively. Defaults to +true+.
    # [:+fill+] If true or a color, the area is filled with the current or specified +fill_color+, respectively. Defaults to +false+.
    # [:+clip+] If true and a block is given, the shape acts as a clipping boundary for anything drawn within the supplied block.
    # [:+reverse+] Draw polygon clockwise.  This is useful for drawing hollow shapes.
    #
    # These current settings also apply: +line_color+, +line_width+, +line_dash_pattern+ and +fill_color+.
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
    # [+points+] array of +Location+ structs
    def curve_points(points)
      cur_page.curve_points(points)
    end

    # Returns array of +Location+ structs for circle, suitable for feeding to +curve_points+ method.  See +circle+ method.
    def points_for_circle(x, y, r)
      cur_page.points_for_circle(x, y, r)
    end

    # Draw a circle with center <tt>x, y</tt> and radius +r+.
    # Direction is counterclockwise (anticlockwise), unless :+reverse+ option is specified.
    #
    # The following +options+ apply:
    # [:+border+] If true or a color, a border is drawn with the current or specified +line_color+, respectively. Defaults to +true+.
    # [:+fill+] If true or a color, the area is filled with the current or specified +fill_color+, respectively. Defaults to +false+.
    # [:+clip+] The shape acts as a clipping boundary for anything drawn within the supplied block.
    # [:+reverse+] Draw circle clockwise.  Useful for drawing hollow shapes.
    #
    # These current settings also apply: +line_color+, +line_width+, +line_dash_pattern+ and +fill_color+.
    def circle(x, y, r, options={}, &block)
      cur_page.circle(x, y, r, options, &block)
    end

    # Returns array of +Location+ structs for ellipse, suitable for feeding to +curve_points+ method.  See +ellipse+ method.
    def points_for_ellipse(x, y, rx, ry)
      cur_page.points_for_ellipse(x, y, rx, ry)
    end

    # Draw an ellipse with foci (<tt>x, y</tt>) and (<tt>x, y</tt>) and radius +r+.
    # Direction is counterclockwise (anticlockwise), unless :+reverse+ option is specified.
    #
    # The following +options+ apply:
    # [:+border+] If true or a color, a border is drawn with the current or specified +line_color+, respectively. Defaults to +true+.
    # [:+fill+] If true or a color, the area is filled with the current or specified +fill_color+, respectively. Defaults to +false+.
    # [:+clip+] The shape acts as a clipping boundary for anything drawn within the supplied block.
    # [:+reverse+] Draw ellipse clockwise.  Useful for drawing hollow shapes.
    #
    # These current settings also apply: +line_color+, +line_width+, +line_dash_pattern+ and +fill_color+.
    def ellipse(x, y, rx, ry, options={})
      cur_page.ellipse(x, y, rx, ry, options)
    end

    # Returns array of +Location+ structs for arc, suitable for feeding to +curve_points+ method.  See +arc+ method.
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

    # Draw a pie-shaped wedge with origin <tt>x, y</tt> and radius +r+ from +start_angle+ to +end_angle+ degrees.
    # [:+border+] If true or a color, a border is drawn with the current or specified +line_color+, respectively. Defaults to +true+.
    # [:+fill+] If true or a color, the area is filled with the current or specified +fill_color+, respectively. Defaults to +false+.
    # [:+clip+] If true and a block is given, the shape acts as a clipping boundary for anything drawn within the supplied block.
    # [:+reverse+] By default, the bounding path is drawn from <tt>(x, y)</tt> to <tt>(r, start_angle)</tt> through <tt>(r, end_angle)</tt> and back to <tt>(x, y)</tt>.  This order is reversed if <tt>:reverse => true</tt>.  This is useful for drawing hollow shapes.
    #
    # These current settings also apply: +line_color+, +line_width+, +line_dash_pattern+ and +fill_color+.
    def pie(x, y, r, start_angle, end_angle, options={})
      cur_page.pie(x, y, r, start_angle, end_angle, options)
    end

    # Draw an arch with origin <tt>x, y</tt> from +start_angle+ to _end_angle_ degrees.
    # The result is a bounded area between radii <tt>r1</tt> and <tt>r2</tt>.
    #
    # The following +options+ apply:
    # [:+border+] If true or a color, a border is drawn with the current or specified +line_color+, respectively. Defaults to +true+.
    # [:+fill+] If true or a color, the area is filled with the current or specified +fill_color+, respectively. Defaults to +false+.
    # [:+clip+] If true and a block is given, the shape acts as a clipping boundary for anything drawn within the supplied block.
    # [:+reverse+] By default, the bounding path is drawn from <tt>(r1, start_angle)</tt> to <tt>(r1, end_angle)</tt>, <tt>(r2, end_angle)</tt>, <tt>(r2, start_angle)</tt> and back to <tt>(r1, start_angle)</tt>.  This order is reversed if <tt>reverse => true</tt>.  This is useful for drawing hollow shapes.
    #
    # These current settings also apply: +line_color+, +line_width+, +line_dash_pattern+ and +fill_color+.
    def arch(x, y, r1, r2, start_angle, end_angle, options={}, &block)
      cur_page.arch(x, y, r1, r2, start_angle, end_angle, options, &block)
    end

    # Returns array of +Location+ structs representing the vertices of a polygon.  See +polygon+ method.
    def points_for_polygon(x, y, r, sides, options={})
      cur_page.points_for_polygon(x, y, r, sides, options)
    end

    # Draw a polygon with origin <tt>(x, y)</tt>, radius +r+ and the specified number of +sides+.
    #
    # The following +options+ apply:
    # [:+border+] If true or a color, a border is drawn with the current or specified +line_color+, respectively. Defaults to +true+.
    # [:+fill+] If true or a color, the area is filled with the current or specified +fill_color+, respectively. Defaults to +false+.
    # [:+clip+] If true and a block is given, the shape acts as a clipping boundary for anything drawn within the supplied block.
    # [:+reverse+] Draw polygon clockwise.  This is useful for drawing hollow shapes.
    #
    # These current settings also apply: +line_color+, +line_width+, +line_dash_pattern+ and +fill_color+.
    def polygon(x, y, r, sides, options={})
      cur_page.polygon(x, y, r, sides, options)
    end

    # Draw a star with origin <tt>(x, y)</tt>, outer radius +r1+, inner radius +r2+ and the specified number of +sides+.
    #
    # The following +options+ apply:
    # [:+border+] If true or a color, a border is drawn with the current or specified +line_color+, respectively. Defaults to +true+.
    # [:+fill+] If true or a color, the area is filled with the current or specified +fill_color+, respectively. Defaults to +false+.
    # [:+clip+] If true and a block is given, the shape acts as a clipping boundary for anything drawn within the supplied block.
    # [:+reverse+] Draw polygon clockwise.  This is useful for drawing hollow shapes.
    #
    # These current settings also apply: +line_color+, +line_width+, +line_dash_pattern+ and +fill_color+.
    def star(x, y, r1, r2, points, options={})
      cur_page.star(x, y, r1, r2, points, options)
    end

    # Returns current status of auto_path.  Defaults to +true+.  False while in a block given to +path+ method.
    # When +true+, paths are automatically stroked before a new, non-contiguous segment is appended or a closed shape is drawn.
    def auto_path
      cur_page.auto_path
    end

    # Turn off auto_path.  If a block is given, yields to it before filling and/or stroking anything drawn within it according to
    # the +options+ supplied.  The path may be non-contiguous.  Shapes may be hollow when inner paths are drawn in the opposite
    # direction as outer paths.
    #
    # The following options apply:
    # [:+stroke+] If true or a color, the path will be stroked with the current or specified +line_color+, respectively.  Defaults to +false+.
    # [:+fill+] If true or a color, the area bounded by the path will be filled with the current or specified +fill_color+, respectively.  Defaults to +false+.
    def path(options={}, &block)
      cur_page.path(options, &block)
    end

    # Fill current path (begun by +path+ method) and resume +auto_path+.  The +line_color+ and +fill_color+ in effect before +path+
    # was begun are restored.  Raises Exception if no current path exists.
    def fill
      cur_page.fill
    end

    # Stroke current path (begun by +path+ method) and resume +auto_path+.  The +line_color+ and +fill_color+ in effect before +path+
    # was begun are restored.  Raises Exception if no current path exists.
    def stroke
      cur_page.stroke
    end

    # Fill and stroke current path (begun by +pat+ method) and resume +auto_path+.  The +line_color+ and +fill_color+ in effect
    # before +path+ was begun are restored.  Raises Exception if no current path exists.
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

    # Set the shape to be used at the ends of lines.  If no style is specified, returns current style.
    # [+style+] One of the symbols :butt_cap, :round_cap or :projecting_square_cap, or a string 'butt_cap', 'round_cap' or 'projecting_square_cap'.
    def line_cap_style(style=nil)
      cur_page.line_cap_style(style)
    end

    # Set the pattern of dashes and gaps used to draw lines.  If no pattern is specified, returns current pattern.
    # [+pattern+] A string of the form '[dash gap] phase' or one of the symbols :+solid+, :+dotted+ or :+dashed+.
    # When a symbol is specified, dash and gap lengths are multiplied by +line_width+ for proportion.
    def line_dash_pattern(pattern=nil)
      cur_page.line_dash_pattern(pattern)
    end

    # Set line width used when stroking paths.  If no width is specified, returns current +line_width+.
    # [+value+] If +value+ is a number, the new +line_width+ setting. If +value+ is a symbol (such as :pt, :cm or :in), the units to return the current +line_width+ in.  If +value+ is a string, it may include the units as a suffix, e.g. "5.5in" for 5.5 inches.
    # [+units+] Units value is expressed in.  Defaults to current units setting.
    def line_width(value=nil, units=nil)
      cur_page.line_width(value, units)
    end

    # Returns hash of named colors consisting of (name, color) pairs.
    # Initial value comes from EideticPDF::PdfK::NAMED_COLORS, but may be augmented or replaced.
    def named_colors
      @named_colors ||= PdfK::NAMED_COLORS.dup
    end

    # Set line color, returning previous line color.  If no color is specified, returns current font color.
    # [+color+] Tuple (array) containing [red, green, blue] components of new color (where components range from 0..255), string key into +named_colors+ or integer encoded from rgb bytes where blue is in the least-significant byte.
    # Return values are always in string or integer form.
    def line_color(color=nil)
      cur_page.line_color(color)
    end

    # Set fill color, returning previous fill color.  If no color is specified, returns current fill color.
    # [+color+] Tuple (array) containing [red, green, blue] components of new color (where components range from 0..255) or integer encoded from rgb bytes where blue is in the least-significant byte.
    # Return values are always in integer form.
    def fill_color(color=nil)
      cur_page.fill_color(color)
    end

    # Set font color, returning previous font color.  If no color is specified, returns current font color.
    # [+color+] Tuple (array) containing [red, green, blue] components of new color (where components range from 0..255) or integer encoded from rgb bytes where blue is in the least-significant byte.
    # Return values are always in integer form.
    def font_color(color=nil)
      cur_page.font_color(color)
    end

    # Print text, starting from the current position.
    #
    # The following options apply:
    # [:+align+] When :+left+, left edge of text is aligned to current position.  When :+center+, text is centered at current position.  When :+right+, right edge of text is aligned to current position.  When any alignment is specified, the pen is restored to its original location.
    # [:+angle+] Print text at the specified +angle+ in degrees.  Defaults to 0.
    # [:+scale+] Horizontal scaling of text, specified as ratio to normal width.  Defaults to 1.0.  Cannot be combined with :+clip+.
    # [:+underline+] Override +underline+ setting for this piece of text.
    # [:+clip+] If true and a block is given, the edges of the text act as a clipping boundary for anything drawn within the supplied block.  Cannot be combined with :+scale+.
    # [:+fill+] (Only applicable with :+clip+) Fill text and add to path for clipping.
    # [:+stroke+] (Only applicable with :+clip+) Stroke text with current +line_color+ and add to path for clipping.
    #
    # These current settings also apply: +font+, +font_color+, +line_color+ (when outlines are stroked) and vertical text alignment (+v_text_align+).
    def print(text, options={}, &block)
      cur_page.print(text, options, &block)
    end

    # Move to <tt>(x, y)</tt> and print text.  See +print+ method.
    def print_xy(x, y, text, options={}, &block)
      cur_page.print_xy(x, y, text, options, &block)
    end

    # Print one or more lines of text before moving to the next line, as specified by +indent+.
    def puts(text='', options={}, &block)
      cur_page.puts(text, options, &block)
    end

    # Move to <tt>(x, y)</tt> and print one or more lines of text indented to +x+.  See +puts+ method.
    def puts_xy(x, y, text, options={}, &block)
      cur_page.puts_xy(x, y, text, options={}, &block)
    end

    # Move pen down one or more lines and back to current indent.
    # [+count+] Number of lines to move down.
    def new_line(count=1)
      cur_page.new_line(count)
    end

    # Returns width of a string as rendered using the current font.
    def width(text)
      cur_page.width(text)
    end

    # Breaks text into tokens and reassembles into array of strings, each one not exceeding +length+.
    # Newlines are respected and all other white space is preserved.
    def wrap(text, length)
      cur_page.wrap(text, length)
    end

    # Returns text height, based on the current font, excluding external leading.
    # [+units+] Units the value is returned in.
    def text_height(units=nil)
      cur_page.text_height(units)
    end

    # Returns height of a line or array of lines, including external leading as determined by +line_height+.
    # [+text+] Line or array of lines to be measured.  Height is determined only by current font and number of lines.
    # [+units+] Units result should be expressed in.  Defaults to current +units+.
    def height(text='', units=nil) # may not include external leading?
      cur_page.height(text, units)
    end

    # Wrap +text+ and render with the following +options+.
    # [:+width+] Maximum width to wrap text within.  Defaults to the canvas width minus the current horizontal position.
    # [:+height+] Maximum height allowed.  Any text not rendered will be returned by the method call.  Defaults to the canvas height minus the current vertical position.
    # [:+bullet+] Render paragraph as a bullet, using the named bullet as defined using the +bullet+ method.  The bullet width is subtracted from the :+width+ specified.
    def paragraph(text, options={})
      cur_page.paragraph(text, options)
    end

    # Move to <tt>(x, y)</tt> and render paragraph.
    def paragraph_xy(x, y, text, options={})
      cur_page.paragraph_xy(x, y, text, options)
    end

    # Set vertical text alignment.  This is the part of the text that would coincide with a line if one were drawn at the same
    # coordinates as the text.
    # [:+above+] At the top of the text, plus an amount equal to the height of descenders.
    # [:+top+] At the top of the text--text is rendered below the line.
    # [:+middle+] Through the middle of the text, like a strikeout.
    # [:+base+] At the base of the text--text is rendered above the line, except for descenders.
    # [:+below+] Below the text--text is rendered above the line, including descenders.
    # Default is :+top+.
    def v_text_align(vta=nil)
      cur_page.v_text_align(vta)
    end

    # Set new underline status, returning previous status.  If new status is not specified, returns current underline status.
    def underline(underline=nil)
      cur_page.underline(underline)
    end

    # Returns an array of font names, including weight and style, from the (local) fonts directory.
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

    # Set font, returning previous font.  If no font is specified, returns current font.
    # [+name+] Base name of a Type1 font with metrics file in fonts directory.
    # [+size+] Size of font in points.  See also +font_size+ method.
    # The following +options+ apply:
    # [:+style+] Bold, Italic, Oblique or a combination of weight and style such as BoldItalic or BoldOblique.  See +font_style+ method.
    # [:+color+] Font color as given to +font_color+ method.  Color is unchanged if not specified.
    # [:+encoding+] Currently-supported encodings include StandardEncoding, WinAnsiEncoding/CP1250, CP1250, CP1254, ISO-8859-1, ISO-8859-2, ISO-8859-3, ISO-8859-4, ISO-8859-7, ISO-8859-9, ISO-8859-10, ISO-8859-13, ISO-8859-14, ISO-8859-15, ISO-8859-16, MacTurkish or Macintosh.  Defaults to WinAnsiEncoding.
    # [:+sub_type+] Currently only Type1 fonts are supported.  Defaults to Type1.
    # [:+fill+] Fill text with current +font_color+.  Defaults to +true+.
    # [:+stroke+] Stroke text with current +line_color+.  Defaults to +false+.
    def font(name=nil, size=nil, options={})
      cur_page.font(name, size, options)
    end

    # Set font style, returning previous font style.  If no style is specified, returns current font style.
    # [+style+] Bold (or other weight), Italic, Oblique or combination such as BoldItalic or BoldOblique.
    # Exact weights and combinations available depend on the font specification files in the (local) fonts directory.
    def font_style(style=nil)
      cur_page.font_style(style)
    end

    # Set font size, returning previous font size.  If no size is specified, returns current font size.
    # [+size+] Size of font in points.
    def font_size(size=nil)
      cur_page.font_size(size)
    end

    # Returns +true+ if image is a buffer beginning with a JPEG signature.
    def jpeg?(image)
      cur_page.jpeg?(image)
    end

    # Returns a tuple (array) of image dimensions of the form [width, height, components, bits_per_component].
    # Raises ArgumentError if +image+ is not a JPEG.
    def jpeg_dimensions(image)
      cur_page.jpeg_dimensions(image)
    end

    def load_image(image_file_name, stream=nil) # :nodoc:
      cur_page.load_image(image_file_name, stream)
    end

    # Load graphic file (currently only JPEG is supported) from disk (or network, if open-uri library is loaded) and display at the specified location.
    # [+image_file_name+] Path or URL to image.
    # [+x+] Left edge of image is placed at this offset.  Defaults to <tt>pen_pos.x</tt>.
    # [+y+] Top edge of image is placed at this offset.  Defaults to <tt>pen_pos.y</tt>.
    # [+width+] Width to make image.  Defaults to natural image width or a width proportionate to +height+ if +height+ is specified.
    # [+height+] Height to make image.  Defaults to natural image height or a height proportionate to +width+ if +width+ is specified.
    def print_image_file(image_file_name, x=nil, y=nil, width=nil, height=nil)
      cur_page.print_image_file(image_file_name, x, y, width, height)
    end

    # Display graphic (currently only JPEG is supported) from disk (or network, if open-uri library is loaded) and display at the specified location.
    # [+data+] Buffer containing image.
    # [+x+] Left edge of image is placed at this offset.  Defaults to <tt>pen_pos.x</tt>.
    # [+y+] Top edge of image is placed at this offset.  Defaults to <tt>pen_pos.y</tt>.
    # [+width+] Width to make image.  Defaults to natural image width or a width proportionate to +height+ if +height+ is specified.
    # [+height+] Height to make image.  Defaults to natural image height or a height proportionate to +width+ if +width+ is specified.
    def print_image(data, x=nil, y=nil, width=nil, height=nil)
      cur_page.print_image(data, x, y, width, height)
    end

    def print_link(s, uri) # :nodoc:
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

    # Rotate anything drawn within the supplied block +angle+ degrees around origin <tt>(x, y)</tt>.
    def rotate(angle, x, y, &block)
      cur_page.rotate(angle, x, y, &block)
    end

    def scale(x, y, scale_x, scale_y, &block)
      cur_page.scale(x, y, scale_x, scale_y, &block)
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
