#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-07-13.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

module PdfW
  class PageStyle
    attr_reader :page_size, :crop_size, :orientation, :langscape
    
    def initialize(page_size, crop_size, landscape=false, orientation=false)
      :page_size, :crop_size, :orientation, :langscape
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

    def make_size_rectangle(size, orientation)
      SIZES[size][orientation]
    end
  end
end