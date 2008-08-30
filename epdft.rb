#!/usr/bin/env ruby
# encoding: ASCII-8BIT
#
#  Created by Brent Rowland on 2007-11-27.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

module EideticPDF
  module TextLine # :nodoc:
    def height
      @height ||= map { |p| 0.001 * p.font.height * p.font.size }.max
    end

    def ascent
      @ascent ||= map { |p| 0.001 * p.font.ascent * p.font.size }.max
    end

    def descent
      @descent ||= map { |p| 0.001 * p.font.descent * p.font.size }.min
    end

    def width
      @width ||= inject(0) { |total, p| total + p.width }
    end

    def chars
      @chars ||= inject(0) { |total, p| total + p.chars }
    end

    def tokens
      @tokens ||= inject(0) { |total, p| total + p.tokens }
    end
  end

  module PdfText # :nodoc: all
    class TextPiece
      attr_accessor :text, :width, :font, :color, :underline, :chars, :tokens

      def initialize(text, width, font, color, underline, chars, tokens)
        @text, @width, @font, @color, @underline, @chars, @tokens = text, width, font, color, underline, chars, tokens
      end

      def initialize_copy(other)
        @text = @text.clone
      end
    end

    class RichText
      TOKEN_RE = /\n|\t|[ ]|[\S]+-+|[\S]+/
      attr_reader :words

      def initialize(text=nil, font=nil, options={})
        @words = []
        add(text, font, options) unless text.nil?
      end

      def initialize_copy(other)
        @words = @words.map { |word| word.clone }
      end

      def add(text, font, options={})
        fsize = font.size * 0.001
        char_spacing, word_spacing = options[:char_spacing] || 0, options[:word_spacing] || 0
        color, underlined = options[:color] || 0, options[:underline] || false
        words = text.scan(TOKEN_RE).map do |token|
          width = 0.0
          token.each_byte do |b|
            width += fsize * font.widths[b] + char_spacing
            width += word_spacing if b == 32 # space
          end
          TextPiece.new(token, width, font, color, underlined, token.length, 1)
        end
        @words.concat(words)
      end

      # merge pieces with identical characteristics
      def merge(text_pieces)
        while !text_pieces.empty? and text_pieces.last.text == ' '
          text_pieces.pop
        end
        text_pieces.inject([]) do |pieces, piece|
          if pieces.empty? or [pieces.last.font, pieces.last.color, pieces.last.underline] != [piece.font, piece.color, piece.underline]
            pieces << piece
          else
            pieces.last.text << piece.text
            pieces.last.width += piece.width
            pieces.last.chars += piece.chars
            pieces.last.tokens += piece.tokens
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

      def lines(width)
        rich_text = self.clone
        result = []
        while line = rich_text.next(width)
          result << line
        end
        result
      end

      def empty?
        @words.empty?
      end

      def height(width=nil)
        return 0 if @words.empty?
        if width.nil?
          f = @words.first.font
          0.001 * f.height * f.size
        else
          lines(width).inject(0) { |total, line| total + line.height }
        end
      end

      def width(max_width)
        lines(max_width).map { |line| line.width }.max
      end
    end
  end
end
