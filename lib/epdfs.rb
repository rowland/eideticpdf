#!/usr/bin/env ruby
# encoding: ASCII-8BIT
#
#  Created by Brent Rowland on 2008-01-12.
#  Copyright (c) 2008, Eidetic Software. All rights reserved.

# Eidetic PDF Support

class Numeric # :nodoc:
  unless 1.respond_to?(:degrees)
    def degrees
      self * Math::PI / 180
    end
  end

  unless 2.respond_to?(:even?)
    def even?
      self % 2 == 0
    end
  end

  unless 1.respond_to?(:odd?)
    def odd?
      self % 2 != 0
    end
  end
end

module EideticPDF
  ImageReadMode = "".respond_to?(:encoding) ? "rb:binary" : "rb"

  module Statistics # :nodoc:
    def sum
      self.inject(0) { |total, obj| total + obj }
    end

    def mean
      self.sum.quo(self.size)
    end
  end

  class PropertyStack # :nodoc:
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

  class ColorStack # :nodoc:
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

  module JpegInfo # :nodoc:
    def jpeg?(image)
      # image[0, 2] == "\xFF\xD8"
      image[0, 2].hash == "\xFF\xD8".hash
    end

    def jpeg_dimensions(image)
      raise ArgumentError, "Not a JPEG" unless jpeg?(image)
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
    
    module_function :jpeg?, :jpeg_dimensions
  end
end
