#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-11-27.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

module EideticPDF
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
        char_spacing = options[:char_spacing] || 0
        word_spacing = options[:word_spacing] || 0
        color = options[:color] || 0
        underlined = options[:underline]
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

      def next(width)
        # remove leading spaces
        while !@words.empty? and @words.first.text == ' '
          @words.shift
        end
        return nil if @words.empty?
        # measure how many words will fit
        i, phrase_width = 0, 0
        while i < @words.size and phrase_width + @words[i].width < width
          phrase_width += @words[i].width
          i += 1
          break if @words[i-1].text == "\n"
        end
        i = 1 if i == 0 # fetch minimum of 1 word. todo: break words?
        result = @words.slice!(0, i)
        # merge words with identical characteristics
        i = 1
        while i < result.size
          if [result[i-1].font, result[i-1].color, result[i-1].underline] != [result[i].font, result[i].color, result[i].underline]
            i += 1
          else
            result[i-1].text << result[i].text
            result.delete_at(i)
          end
        end
        result
      end

      def empty?
        @words.empty?
      end

      def height
        if @words.empty?
          return 0
        else
          f = @words.first.font
          0.001 * f.height * f.size
        end
      end
    end
  end
end
