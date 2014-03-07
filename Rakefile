require "bundler/gem_tasks"

require "rake/testtask"
require "rdoc/task"

gemspec = eval(File.read(Dir["*.gemspec"].first))

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the acts_as_paranoid plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.pattern = 'test/test_*.rb'
  t.verbose = true
end

desc 'Generate documentation for the acts_as_paranoid plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'ActsAsParanoid'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Install gem locally"
task :install => :build do
  system "gem install pkg/#{gemspec.name}-#{gemspec.version}"
end

desc "Clean automatically generated files"
task :clean do
  FileUtils.rm_rf "pkg"
end
