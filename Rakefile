require 'rubygems'
require 'rubygems/package_task'
require 'rake/testtask'
require 'rcov/rcovtask'

spec = Gem::Specification.new do |s|
  s.name = "eideticpdf"
  s.version = "0.9.9"
  s.date = "2013-03-13"
  s.summary = "PDF Library"
  s.requirements = "Ruby 1.8.x"
  # s.require_path = '.'
#  s.autorequire = 'epdfdw'
  s.author = "Brent Rowland"
  s.email = "rowland@rowlandresearch.com"
  s.homepage = "https://github.com/rowland/eideticpdf"
  s.rubyforge_project = "eideticpdf"
  s.test_file = "test/pdf_tests.rb"
  s.has_rdoc = true
  # s.extra_rdoc_files = ['README']
  s.rdoc_options << '--title' << 'Eidetic PDF' << '--main' << 'lib/epdfdw.rb' << '-x' << 'test'
  s.files = FileList["lib/*.rb"] + FileList["test/test*.rb"] + ['test/testimg.jpg'] + FileList["fonts/*.afm"] + FileList["fonts/*.inf"]
  s.platform = Gem::Platform::RUBY
end

Gem::PackageTask.new(spec) do |pkg|
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

desc "Clean up files generated by tests."
task :clean do
  rm_f "test.pdf"
  rm_f "encoding_test.pdf"
  rm_f "test/test.pdf"
  rm_f "test/encoding_test.pdf"
end

desc "Build documentation."
task :doc do
  `ruby doc/build_documentation.rb`
end
