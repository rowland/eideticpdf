#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2008-01-12.
#  Copyright (c) 2008, Eidetic Software. All rights reserved.

# Eidetic PDF Support

unless 1.respond_to?(:degrees)
  class Numeric
    def degrees
      self * Math::PI / 180
    end
  end
end

module EideticPDF
  module Statistics
    def sum
      self.inject(0) { |total, obj| total + obj }
    end

    def mean
      self.sum.quo(self.size)
    end
  end
end
