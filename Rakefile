require 'rubygems'
require 'rake/gempackagetask'
require 'rake/testtask'
require 'rcov/rcovtask'

spec = Gem::Specification.new do |s|
  s.name = "eideticpdf"
  s.version = "0.9.1"
  s.date = "2008-01-12"
  s.summary = "PDF Library"
  s.requirements = "Ruby 1.8.x"
  s.require_path = '.'
  s.autorequire = 'epdfdw'
  s.email = "brent.rowland@gmail.com"
  s.homepage = "http://www.eideticsoftware.com"
  # s.rubyforge_project = "eideticpdf"
  s.test_file = "test/pdf_tests.rb"
  s.has_rdoc = false
  # s.extra_rdoc_files = ['README']
  # s.rdoc_options << '--title' << 'Eidetic PDF' << '--main' << 'README' << '-x' << 'test'
  s.files = ['epdfafm.rb', 'epdfdw.rb', 'epdfk.rb', 'epdfo.rb', 'epdfs.rb', 'epdfsw.rb', 'epdft.rb', 'epdftt.rb', 'epdfw.rb'] + 
    FileList["test/test*.rb"] + ['test/testimg.jpg'] + 
    FileList["fonts/*.afm"] + FileList["fonts/*.inf"]
  s.platform = Gem::Platform::RUBY
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
  pkg.need_zip = true
end

Rake::TestTask.new do |t|
  # t.libs << "test"
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end

Rcov::RcovTask.new do |t|
  # t.libs << "test"
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end
