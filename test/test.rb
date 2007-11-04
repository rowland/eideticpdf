#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-09-30.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

$: << File.dirname(__FILE__) + '/../'
require 'pdfw'
include PdfW

docw = PdfDocumentWriter.new
docw.begin_doc
docw.start_page(:units => :in)
# test move_to and line_to
docw.move_to(1, 1)
docw.line_to(7.5, 1)
docw.line_to(7.5, 10)
docw.line_to(1, 10)
docw.line_to(1, 1)
# test rectangle
docw.rectangle(2, 2, 4.5, 7)
# test circle
docw.circle(4.25, 5.5, 3.25)
docw.end_page
docw.start_page(:units => :in)
docw.move_to(1, 1)
docw.set_font("Helvetica", 12)
docw.print("Hello, World!")
docw.end_page
docw.end_doc

File.open("test.pdf","w") { |f| f.write(docw) }
print docw
