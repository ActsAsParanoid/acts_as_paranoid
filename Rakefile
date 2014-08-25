require "bundler/gem_tasks"

require "rake/testtask"
require "rdoc/task"

gemspec = eval(File.read(Dir["*.gemspec"].first))

desc 'Default: run unit tests.'
task :default => "test:all"

namespace :test do
  %w(active_record_edge active_record_40 active_record_41 active_record_42).each do |version|
    desc "Test acts_as_paranoid against #{version}"
    task version do
      sh "BUNDLE_GEMFILE='gemfiles/#{version}.gemfile' bundle --quiet"
      sh "BUNDLE_GEMFILE='gemfiles/#{version}.gemfile' bundle exec rake -t test"
    end
  end

  desc "Run all tests for acts_as_paranoid"
  task :all do
    %w(active_record_edge active_record_40 active_record_41 active_record_42).each do |version|
      sh "BUNDLE_GEMFILE='gemfiles/#{version}.gemfile' bundle --quiet"
      sh "BUNDLE_GEMFILE='gemfiles/#{version}.gemfile' bundle exec rake -t test"
    end
  end
end

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
