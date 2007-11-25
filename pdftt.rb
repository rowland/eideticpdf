#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2007-08-26.
#  Copyright (c) 2007, Eidetic Software. All rights reserved.

module EideticPDF
  module PdfTT
    NUM_FONTS = 12

    FONT_WIDTHS = [
      [ # 0 Arial
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #   0 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #  10 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #  20 
        0, 0, 278, 278, 355, 556, 556, 889, 667, 191,               #  30 
        333, 333, 389, 584, 278, 333, 278, 278, 556, 556,           #  40 
        556, 556, 556, 556, 556, 556, 556, 556, 278, 278,           #  50 
        584, 584, 584, 556, 1015, 667, 667, 722, 722, 667,          #  60 
        611, 778, 722, 278, 500, 667, 556, 833, 722, 778,           #  70 
        667, 778, 722, 667, 611, 722, 667, 944, 667, 667,           #  80 
        611, 278, 278, 278, 469, 556, 333, 556, 556, 500,           #  90 
        556, 556, 278, 556, 556, 222, 222, 500, 222, 833,           # 100 
        556, 556, 556, 556, 333, 500, 278, 556, 500, 722,           # 110 
        500, 500, 500, 334, 260, 334, 584, 750, 556, 750,           # 120 
        222, 556, 333, 1000, 556, 556, 333, 1000, 667, 333,         # 130 
        1000, 750, 611, 750, 750, 222, 222, 333, 333, 350,          # 140 
        556, 1000, 333, 1000, 500, 333, 944, 750, 500, 667,         # 150 
        278, 333, 556, 556, 556, 556, 260, 556, 333, 737,           # 160 
        370, 556, 584, 333, 737, 552, 400, 549, 333, 333,           # 170 
        333, 576, 537, 278, 333, 333, 365, 556, 834, 834,           # 180 
        834, 611, 667, 667, 667, 667, 667, 667, 1000, 722,          # 190 
        667, 667, 667, 667, 278, 278, 278, 278, 722, 722,           # 200 
        778, 778, 778, 778, 778, 584, 778, 722, 722, 722,           # 210 
        722, 667, 667, 611, 556, 556, 556, 556, 556, 556,           # 220 
        889, 500, 556, 556, 556, 556, 278, 278, 278, 278,           # 230 
        556, 556, 556, 556, 556, 556, 556, 549, 611, 556,           # 240 
        556, 556, 556, 500, 556, 500],                              # 250 
      [ # 1 Arial,Bold                                                    
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #   0 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #  10 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #  20 
        0, 0, 278, 333, 474, 556, 556, 889, 722, 238,               #  30 
        333, 333, 389, 584, 278, 333, 278, 278, 556, 556,           #  40 
        556, 556, 556, 556, 556, 556, 556, 556, 333, 333,           #  50 
        584, 584, 584, 611, 975, 722, 722, 722, 722, 667,           #  60 
        611, 778, 722, 278, 556, 722, 611, 833, 722, 778,           #  70 
        667, 778, 722, 667, 611, 722, 667, 944, 667, 667,           #  80 
        611, 333, 278, 333, 584, 556, 333, 556, 611, 556,           #  90 
        611, 556, 333, 611, 611, 278, 278, 556, 278, 889,           # 100 
        611, 611, 611, 611, 389, 556, 333, 611, 556, 778,           # 110 
        556, 556, 500, 389, 280, 389, 584, 750, 556, 750,           # 120 
        278, 556, 500, 1000, 556, 556, 333, 1000, 667, 333,         # 130 
        1000, 750, 611, 750, 750, 278, 278, 500, 500, 350,          # 140 
        556, 1000, 333, 1000, 556, 333, 944, 750, 500, 667,         # 150 
        278, 333, 556, 556, 556, 556, 280, 556, 333, 737,           # 160 
        370, 556, 584, 333, 737, 552, 400, 549, 333, 333,           # 170 
        333, 576, 556, 278, 333, 333, 365, 556, 834, 834,           # 180 
        834, 611, 722, 722, 722, 722, 722, 722, 1000, 722,          # 190 
        667, 667, 667, 667, 278, 278, 278, 278, 722, 722,           # 200 
        778, 778, 778, 778, 778, 584, 778, 722, 722, 722,           # 210 
        722, 667, 667, 611, 556, 556, 556, 556, 556, 556,           # 220 
        889, 556, 556, 556, 556, 556, 278, 278, 278, 278,           # 230 
        611, 611, 611, 611, 611, 611, 611, 549, 611, 611,           # 240 
        611, 611, 611, 556, 611, 556],                              # 250 
      [ # 2 Arial,Italic                                                  
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #   0 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #  10 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #  20 
        0, 0, 278, 278, 355, 556, 556, 889, 667, 191,               #  30 
        333, 333, 389, 584, 278, 333, 278, 278, 556, 556,           #  40 
        556, 556, 556, 556, 556, 556, 556, 556, 278, 278,           #  50 
        584, 584, 584, 556, 1015, 667, 667, 722, 722, 667,          #  60 
        611, 778, 722, 278, 500, 667, 556, 833, 722, 778,           #  70 
        667, 778, 722, 667, 611, 722, 667, 944, 667, 667,           #  80 
        611, 278, 278, 278, 469, 556, 333, 556, 556, 500,           #  90 
        556, 556, 278, 556, 556, 222, 222, 500, 222, 833,           # 100 
        556, 556, 556, 556, 333, 500, 278, 556, 500, 722,           # 110 
        500, 500, 500, 334, 260, 334, 584, 750, 556, 750,           # 120 
        222, 556, 333, 1000, 556, 556, 333, 1000, 667, 333,         # 130 
        1000, 750, 611, 750, 750, 222, 222, 333, 333, 350,          # 140 
        556, 1000, 333, 1000, 500, 333, 944, 750, 500, 667,         # 150 
        278, 333, 556, 556, 556, 556, 260, 556, 333, 737,           # 160 
        370, 556, 584, 333, 737, 552, 400, 549, 333, 333,           # 170 
        333, 576, 537, 278, 333, 333, 365, 556, 834, 834,           # 180 
        834, 611, 667, 667, 667, 667, 667, 667, 1000, 722,          # 190 
        667, 667, 667, 667, 278, 278, 278, 278, 722, 722,           # 200 
        778, 778, 778, 778, 778, 584, 778, 722, 722, 722,           # 210 
        722, 667, 667, 611, 556, 556, 556, 556, 556, 556,           # 220 
        889, 500, 556, 556, 556, 556, 278, 278, 278, 278,           # 230 
        556, 556, 556, 556, 556, 556, 556, 549, 611, 556,           # 240 
        556, 556, 556, 500, 556, 500],                              # 250 
      [ # 3 Arial,BoldItalic                                              
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #   0 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #  10 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #  20 
        0, 0, 278, 333, 474, 556, 556, 889, 722, 238,               #  30 
        333, 333, 389, 584, 278, 333, 278, 278, 556, 556,           #  40 
        556, 556, 556, 556, 556, 556, 556, 556, 333, 333,           #  50 
        584, 584, 584, 611, 975, 722, 722, 722, 722, 667,           #  60 
        611, 778, 722, 278, 556, 722, 611, 833, 722, 778,           #  70 
        667, 778, 722, 667, 611, 722, 667, 944, 667, 667,           #  80 
        611, 333, 278, 333, 584, 556, 333, 556, 611, 556,           #  90 
        611, 556, 333, 611, 611, 278, 278, 556, 278, 889,           # 100 
        611, 611, 611, 611, 389, 556, 333, 611, 556, 778,           # 110 
        556, 556, 500, 389, 280, 389, 584, 750, 556, 750,           # 120 
        278, 556, 500, 1000, 556, 556, 333, 1000, 667, 333,         # 130 
        1000, 750, 611, 750, 750, 278, 278, 500, 500, 350,          # 140 
        556, 1000, 333, 1000, 556, 333, 944, 750, 500, 667,         # 150 
        278, 333, 556, 556, 556, 556, 280, 556, 333, 737,           # 160 
        370, 556, 584, 333, 737, 552, 400, 549, 333, 333,           # 170 
        333, 576, 556, 278, 333, 333, 365, 556, 834, 834,           # 180 
        834, 611, 722, 722, 722, 722, 722, 722, 1000, 722,          # 190 
        667, 667, 667, 667, 278, 278, 278, 278, 722, 722,           # 200 
        778, 778, 778, 778, 778, 584, 778, 722, 722, 722,           # 210 
        722, 667, 667, 611, 556, 556, 556, 556, 556, 556,           # 220 
        889, 556, 556, 556, 556, 556, 278, 278, 278, 278,           # 230 
        611, 611, 611, 611, 611, 611, 611, 549, 611, 611,           # 240 
        611, 611, 611, 556, 611, 556],                              # 250 
      [ # 4 TimesNewRoman                                                 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #   0 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #  10 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #  20 
        0, 0, 250, 333, 408, 500, 500, 833, 778, 180,               #  30 
        333, 333, 500, 564, 250, 333, 250, 278, 500, 500,           #  40 
        500, 500, 500, 500, 500, 500, 500, 500, 278, 278,           #  50 
        564, 564, 564, 444, 921, 722, 667, 667, 722, 611,           #  60 
        556, 722, 722, 333, 389, 722, 611, 889, 722, 722,           #  70 
        556, 722, 667, 556, 611, 722, 722, 944, 722, 722,           #  80 
        611, 333, 278, 333, 469, 500, 333, 444, 500, 444,           #  90 
        500, 444, 333, 500, 500, 278, 278, 500, 278, 778,           # 100 
        500, 500, 500, 500, 333, 389, 278, 500, 500, 722,           # 110 
        500, 500, 444, 480, 200, 480, 541, 778, 500, 778,           # 120 
        333, 500, 444, 1000, 500, 500, 333, 1000, 556, 333,         # 130 
        889, 778, 611, 778, 778, 333, 333, 444, 444, 350,           # 140 
        500, 1000, 333, 980, 389, 333, 722, 778, 444, 722,          # 150 
        250, 333, 500, 500, 500, 500, 200, 500, 333, 760,           # 160 
        276, 500, 564, 333, 760, 500, 400, 549, 300, 300,           # 170 
        333, 576, 453, 250, 333, 300, 310, 500, 750, 750,           # 180 
        750, 444, 722, 722, 722, 722, 722, 722, 889, 667,           # 190 
        611, 611, 611, 611, 333, 333, 333, 333, 722, 722,           # 200 
        722, 722, 722, 722, 722, 564, 722, 722, 722, 722,           # 210 
        722, 722, 556, 500, 444, 444, 444, 444, 444, 444,           # 220 
        667, 444, 444, 444, 444, 444, 278, 278, 278, 278,           # 230 
        500, 500, 500, 500, 500, 500, 500, 549, 500, 500,           # 240 
        500, 500, 500, 500, 500, 500],                              # 250 
      [ # 5 TimesNewRoman,Bold                                            
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #   0 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #  10 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #  20 
        0, 0, 250, 333, 555, 500, 500, 1000, 833, 278,              #  30 
        333, 333, 500, 570, 250, 333, 250, 278, 500, 500,           #  40 
        500, 500, 500, 500, 500, 500, 500, 500, 333, 333,           #  50 
        570, 570, 570, 500, 930, 722, 667, 722, 722, 667,           #  60 
        611, 778, 778, 389, 500, 778, 667, 944, 722, 778,           #  70 
        611, 778, 722, 556, 667, 722, 722, 1000, 722, 722,          #  80 
        667, 333, 278, 333, 581, 500, 333, 500, 556, 444,           #  90 
        556, 444, 333, 500, 556, 278, 333, 556, 278, 833,           # 100 
        556, 500, 556, 556, 444, 389, 333, 556, 500, 722,           # 110 
        500, 500, 444, 394, 220, 394, 520, 778, 500, 778,           # 120 
        333, 500, 500, 1000, 500, 500, 333, 1000, 556, 333,         # 130 
        1000, 778, 667, 778, 778, 333, 333, 500, 500, 350,          # 140 
        500, 1000, 333, 1000, 389, 333, 722, 778, 444, 722,         # 150 
        250, 333, 500, 500, 500, 500, 220, 500, 333, 747,           # 160 
        300, 500, 570, 333, 747, 500, 400, 549, 300, 300,           # 170 
        333, 576, 540, 250, 333, 300, 330, 500, 750, 750,           # 180 
        750, 500, 722, 722, 722, 722, 722, 722, 1000, 722,          # 190 
        667, 667, 667, 667, 389, 389, 389, 389, 722, 722,           # 200 
        778, 778, 778, 778, 778, 570, 778, 722, 722, 722,           # 210 
        722, 722, 611, 556, 500, 500, 500, 500, 500, 500,           # 220 
        722, 444, 444, 444, 444, 444, 278, 278, 278, 278,           # 230 
        500, 556, 500, 500, 500, 500, 500, 549, 500, 556,           # 240 
        556, 556, 556, 500, 556, 500],                              # 250 
      [ # 6 TimesNewRoman,Italic                                          
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #   0 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #  10 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #  20 
        0, 0, 250, 333, 420, 500, 500, 833, 778, 214,               #  30 
        333, 333, 500, 675, 250, 333, 250, 278, 500, 500,           #  40 
        500, 500, 500, 500, 500, 500, 500, 500, 333, 333,           #  50 
        675, 675, 675, 500, 920, 611, 611, 667, 722, 611,           #  60 
        611, 722, 722, 333, 444, 667, 556, 833, 667, 722,           #  70 
        611, 722, 611, 500, 556, 722, 611, 833, 611, 556,           #  80 
        556, 389, 278, 389, 422, 500, 333, 500, 500, 444,           #  90 
        500, 444, 278, 500, 500, 278, 278, 444, 278, 722,           # 100 
        500, 500, 500, 500, 389, 389, 278, 500, 444, 667,           # 110 
        444, 444, 389, 400, 275, 400, 541, 778, 500, 778,           # 120 
        333, 500, 556, 889, 500, 500, 333, 1000, 500, 333,          # 130 
        944, 778, 556, 778, 778, 333, 333, 556, 556, 350,           # 140 
        500, 889, 333, 980, 389, 333, 667, 778, 389, 556,           # 150 
        250, 389, 500, 500, 500, 500, 275, 500, 333, 760,           # 160 
        276, 500, 675, 333, 760, 500, 400, 549, 300, 300,           # 170 
        333, 576, 523, 250, 333, 300, 310, 500, 750, 750,           # 180 
        750, 500, 611, 611, 611, 611, 611, 611, 889, 667,           # 190 
        611, 611, 611, 611, 333, 333, 333, 333, 722, 667,           # 200 
        722, 722, 722, 722, 722, 675, 722, 722, 722, 722,           # 210 
        722, 556, 611, 500, 500, 500, 500, 500, 500, 500,           # 220 
        667, 444, 444, 444, 444, 444, 278, 278, 278, 278,           # 230 
        500, 500, 500, 500, 500, 500, 500, 549, 500, 500,           # 240 
        500, 500, 500, 444, 500, 444],                              # 250 
      [ # 7 Times-BoldItalic                                              
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #   0 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #  10 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                               #  20 
        0, 0, 250, 389, 555, 500, 500, 833, 778, 278,               #  30 
        333, 333, 500, 570, 250, 333, 250, 278, 500, 500,           #  40 
        500, 500, 500, 500, 500, 500, 500, 500, 333, 333,           #  50 
        570, 570, 570, 500, 832, 667, 667, 667, 722, 667,           #  60 
        667, 722, 778, 389, 500, 667, 611, 889, 722, 722,           #  70 
        611, 722, 667, 556, 611, 722, 667, 889, 667, 611,           #  80 
        611, 333, 278, 333, 570, 500, 333, 500, 500, 444,           #  90 
        500, 444, 333, 500, 556, 278, 278, 500, 278, 778,           # 100 
        556, 500, 500, 500, 389, 389, 278, 556, 444, 667,           # 110 
        500, 444, 389, 348, 220, 348, 570, 778, 500, 778,           # 120 
        333, 500, 500, 1000, 500, 500, 333, 1000, 556, 333,         # 130 
        944, 778, 611, 778, 778, 333, 333, 500, 500, 350,           # 140 
        500, 1000, 333, 1000, 389, 333, 722, 778, 389, 611,         # 150 
        250, 389, 500, 500, 500, 500, 220, 500, 333, 747,           # 160 
        266, 500, 606, 333, 747, 500, 400, 549, 300, 300,           # 170 
        333, 576, 500, 250, 333, 300, 300, 500, 750, 750,           # 180 
        750, 500, 667, 667, 667, 667, 667, 667, 944, 667,           # 190 
        667, 667, 667, 667, 389, 389, 389, 389, 722, 722,           # 200 
        722, 722, 722, 722, 722, 570, 722, 722, 722, 722,           # 210 
        722, 611, 611, 500, 500, 500, 500, 500, 500, 500,           # 220 
        722, 444, 444, 444, 444, 444, 278, 278, 278, 278,           # 230 
        500, 556, 500, 500, 500, 500, 500, 549, 500, 556,           # 240 
        556, 556, 556, 444, 500, 444],                              # 250 
      [ # 8 CourierNew                                                    
        600,    0,    0,    0,    0,    0,    0,    0,    0,    0,  #   0 
          0,    0,    0,    0,    0,    0,    0,    0,    0,    0,  #  10 
          0,    0,    0,    0,    0,    0,    0,    0,    0,    0,  #  20 
          0,    0,  600,  600,  600,  600,  600,  600,  600,  600,  #  30 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  40 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  50 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  60 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  70 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  80 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  90 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 100 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 110 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 120 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 130 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 140 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 150 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 160 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 170 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 180 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 190 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 200 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 210 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 220 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 230 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 240 
        600,  600,  600,  600,  600,  600],                         # 250 
      [ # 9 CourierNew,Bold                                               
        600,    0,    0,    0,    0,    0,    0,    0,    0,    0,  #   0 
          0,    0,    0,    0,    0,    0,    0,    0,    0,    0,  #  10 
          0,    0,    0,    0,    0,    0,    0,    0,    0,    0,  #  20 
          0,    0,  600,  600,  600,  600,  600,  600,  600,  600,  #  30 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  40 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  50 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  60 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  70 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  80 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  90 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 100 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 110 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 120 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 130 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 140 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 150 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 160 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 170 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 180 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 190 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 200 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 210 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 220 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 230 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 240 
        600,  600,  600,  600,  600,  600],                         # 250 
      [ # 10 CourierNew,Italic                                             
        600,    0,    0,    0,    0,    0,    0,    0,    0,    0,  #   0 
          0,    0,    0,    0,    0,    0,    0,    0,    0,    0,  #  10 
          0,    0,    0,    0,    0,    0,    0,    0,    0,    0,  #  20 
          0,    0,  600,  600,  600,  600,  600,  600,  600,  600,  #  30 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  40 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  50 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  60 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  70 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  80 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  90 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 100 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 110 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 120 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 130 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 140 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 150 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 160 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 170 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 180 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 190 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 200 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 210 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 220 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 230 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 240 
        600,  600,  600,  600,  600,  600],                         # 250 
      [ # 11 CourierNew,BoldItalic                                         
        600,    0,    0,    0,    0,    0,    0,    0,    0,    0,  #   0 
          0,    0,    0,    0,    0,    0,    0,    0,    0,    0,  #  10 
          0,    0,    0,    0,    0,    0,    0,    0,    0,    0,  #  20 
          0,    0,  600,  600,  600,  600,  600,  600,  600,  600,  #  30 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  40 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  50 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  60 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  70 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  80 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  #  90 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 100 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 110 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 120 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 130 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 140 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 150 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 160 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 170 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 180 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 190 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 200 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 210 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 220 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 230 
        600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  # 240 
        600,  600,  600,  600,  600,  600]]                         # 250 

    FONT_ASCENDERS = [
      905, 905, 905, 905,
      891, 891, 891, 891,
      833, 833, 833, 833]

    FONT_DESCENDERS = [
      -212, -212, -212, -212,
      -216, -216, -216, -216,
      -300, -300, -300, -300]

    FONT_FLAGS = [
      32, 16416, 96, 16480,
      34, 16418, 98, 16482,
      34, 16418, 98, 16482]

    FONT_BBOXES = [
      [ -250, -212, 1213, 1000 ],
      [ -250, -212, 1158, 1000 ],
      [ -250, -212, 1213, 1000 ],
      [ -250, -212, 1184, 1000 ],
      [ -250, -216, 1158, 1000 ],
      [ -250, -216, 1172, 1000 ],
      [ -250, -216, 1158, 1000 ],
      [ -250, -216, 1171, 1000 ],
      [ -250, -300, 767, 1000 ],
      [ -250, -300, 719, 1000 ],
      [ -250, -300, 739, 1000 ],
      [ -250, -300, 712, 1000 ]]

    FONT_ITALIC_ANGLES = [
      0, 0, -11, -11,
      0, 0, -11, -11,
      0, 0, -11, -11]

    FONT_STEM_VS = [
      80, 153, 80, 153,
      73, 136, 73, 131,
      109, 191, 109, 191]

    FONT_X_HEIGHTS = [
      453, 453, 453, 453,
      446, 446, 446, 446,
      417, 417, 417, 417]

    FONT_MISSING_WIDTHS = [
      277, 321, 277, 329,
      321, 250, 376, 325,
      639, 599, 616, 593]

    FONT_STEM_HS = [
      80, 153, 80, 153,
      73, 136, 73, 131,
      109, 191, 109, 191]

    FONT_LEADINGS = [
      150, 150, 150, 150,
      149, 149, 149, 149,
      133, 133, 133, 133]

    FONT_MAX_WIDTHS = [
      1011, 965, 1011, 987,
      965, 977, 965, 976,
      639, 599, 616, 593]

    FONT_AVG_WIDTHS = [
      441, 479, 441, 479,
      401, 427, 402, 412,
      600, 600, 600, 600]

    FONT_CAP_HEIGHTS = [
      905, 905, 905, 905,
      891, 891, 891, 891,
      833, 833, 833, 833]

    FONT_NAMES = [
      'Arial',
      'Arial,Bold',
      'Arial,Italic',
      'Arial,BoldItalic',
      'TimesNewRoman',
      'TimesNewRoman,Bold',
      'TimesNewRoman,Italic',
      'TimesNewRoman,BoldItalic',
      'CourierNew',
      'CourierNew,Bold',
      'CourierNew,Italic',
      'CourierNew,BoldItalic']

    def font_index(font_name)
      FONT_NAMES.index(font_name)
    end
  end
end
