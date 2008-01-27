#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2008-01-26.
#  Copyright (c) 2008 Eidetic Software. All rights reserved.
#
# Eidetic PDF Test Helpers

def assert_array_in_delta(expected_floats, actual_floats, delta)
  expected_floats.each_with_index { |e, i| assert_in_delta(e, actual_floats[i], delta) }
end

def assert_close(expected, actual)
  if expected.respond_to?(:each_with_index) and actual.respond_to?(:[])
    expected.each_with_index { |e, i| assert_in_delta(e, actual[i], 2 ** -20) }
  else
    assert_in_delta(expected, actual, 2 ** -20)
  end
end
