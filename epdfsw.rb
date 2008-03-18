#!/usr/bin/env ruby
# encoding: ASCII-8BIT
#
#  Created by Brent Rowland on 2007-07-13.
#  Copyright (c) 2007, 2008 Eidetic Software. All rights reserved.
#
# Eidetic PDF Stream Writers

require 'epdfo'

module EideticPDF
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
end
