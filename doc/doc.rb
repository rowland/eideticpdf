writer.doc(
  :font => { :name => 'Helvetica', :size => 12 },
  :page_size => :letter,
  :crop_size => :letter, # same as :page_size if not specified
  :orientation => :portrait,
  :pages_up => [1, 1],
  :pages_up_layout => :across,
  :units => :pt,
  :margins => 0,
  :compress => false,
  :built_in_fonts => false,
  :v_text_align => :top,
  :line_height => 1.7,
  :line_width => 1.0, # :pt
  :line_color => 0,
  :fill_color => 0xFFFFFF) do |w|
  # ...
end
