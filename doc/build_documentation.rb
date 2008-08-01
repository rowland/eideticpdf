require 'rubygems'
gem 'eideticrml'
require 'erml'

def build_documentation
  erml = File.join(File.expand_path(File.dirname(__FILE__)), 'eideticpdf.erml')
  render_erml(erml)
end

if $0 == __FILE__
  pdf = build_documentation
  `open #{pdf}` if File.exist?(pdf)
end
