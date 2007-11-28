#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-11-27.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

module EideticPDF
  module PdfText
    TextPiece = Struct.new(:text, :width, :font, :color, :underlined)

    class TextWrapper
      TOKEN_RE = /\n|\t|[ ]|[\S]+-+|[\S]+/
      attr_reader :words

      def initialize(*args)
        @words = []
        add(*args) unless args.empty?
      end

      def add(text, font, size, options={})
        fsize = font.size * 0.001
        char_spacing = options[:char_spacing] || 0
        word_spacing = options[:word_spacing] || 0
        color = options[:color] || 0
        underlined = options[:underlined]
        words = text.scan(TOKEN_RE).map do |token|
          width = 0.0
          token.each_byte do |b|
            width += fsize * font.widths[b] + char_spacing
            width += word_spacing if b == 32 # space
          end
          piece = TextPiece.new(token, width, font, color, underlined)
          piece
        end
        @words.concat(words)
      end

      def next(width)
        while !@words.empty? and @words.first.text == ' '
          @words.shift
        end
        return nil if @words.empty?
        result = []; first = nil
        phrase = @words.shift
        phrase_width = phrase.width
        while phrase_width < width and first = @words.shift
          break if first.text == "\n"
          phrase_width += first.width
          if [phrase.font, phrase.color, phrase.underlined] != [first.font, first.color, first.underlined]
            result << phrase
            phrase = first
          else
            phrase.text << first.text
            phrase.width += first.width
          end
        end
        result << phrase unless phrase == first
        result
      end
    end
  end
end
