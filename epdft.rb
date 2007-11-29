#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-11-27.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

module EideticPDF
  module TextLine
    def height
      map { |p| 0.001 * p.font.height * p.font.size }.max
    end

    def width
      inject(0) { |total, p| total + p.width }
    end
  end

  module PdfText
    TextPiece = Struct.new(:text, :width, :font, :color, :underline)

    class RichText
      TOKEN_RE = /\n|\t|[ ]|[\S]+-+|[\S]+/
      attr_reader :words

      def initialize(text, font, options={})
        @words = []
        add(text, font, options)
      end

      def add(text, font, options={})
        fsize = font.size * 0.001
        char_spacing, word_spacing = options[:char_spacing] || 0, options[:word_spacing] || 0
        color, underlined = options[:color] || 0, options[:underline]
        words = text.scan(TOKEN_RE).map do |token|
          width = 0.0
          token.each_byte do |b|
            width += fsize * font.widths[b] + char_spacing
            width += word_spacing if b == 32 # space
          end
          TextPiece.new(token, width, font, color, underlined)
        end
        @words.concat(words)
      end

      # merge pieces with identical characteristics
      def merge(text_pieces)
        text_pieces.inject([]) do |pieces, piece|
          if pieces.empty? or [pieces.last.font, pieces.last.color, pieces.last.underline] != [piece.font, piece.color, piece.underline]
            pieces << piece
          else
            pieces.last.text << piece.text
            pieces.last.width += piece.width
          end
          pieces
        end
      end

      def next(width)
        # remove leading spaces
        @words.shift while !@words.empty? and @words.first.text == ' '
        return nil if @words.empty?
        # measure how many words will fit
        i, phrase_width = 0, 0.0
        while i < @words.size and phrase_width + @words[i].width < width
          phrase_width += @words[i].width
          i += 1
          break if @words[i-1].text == "\n"
        end
        merge(@words.slice!(0, [i,1].max)).extend(TextLine)
      end

      def empty?
        @words.empty?
      end

      def height
        return 0 if @words.empty?
        f = @words.first.font
        0.001 * f.height * f.size
      end
    end
  end
end
