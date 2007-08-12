#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-07-13.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

require 'pdfu'

module PdfW
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
end