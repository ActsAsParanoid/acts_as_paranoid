# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/manifest/task"
require "rake/testtask"
require "rdoc/task"
require "rubocop/rake_task"

namespace :test do
  versions = Dir["gemfiles/*.gemfile"]
    .map { |gemfile_path| gemfile_path.split(%r{/|\.})[1] }

  versions.each do |version|
    desc "Test acts_as_paranoid against #{version}"
    task version do
      if ENV["RUBYOPT"] =~ %r{bundler/setup}
        raise "Do not run the test:#{version} task with bundle exec!"
      end

      sh "BUNDLE_GEMFILE='gemfiles/#{version}.gemfile' bundle install --quiet"
      sh "BUNDLE_GEMFILE='gemfiles/#{version}.gemfile' bundle exec rake -t test"
    end
  end

  desc "Run all tests for acts_as_paranoid"
  task all: versions
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.pattern = "test/test_*.rb"
  t.verbose = true
end

RuboCop::RakeTask.new

desc "Generate documentation for the acts_as_paranoid plugin."
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.title    = "ActsAsParanoid"
  rdoc.options << "--line-numbers" << "--inline-source"
  rdoc.rdoc_files.include("README")
  rdoc.rdoc_files.include("lib/**/*.rb")
end

desc "Clean automatically generated files"
task :clean do
  FileUtils.rm_rf "pkg"
end

Rake::Manifest::Task.new do |t|
  t.patterns = ["{lib}/**/*", "LICENSE", "*.md"]
end

task build: ["manifest:check"]

desc "Default: run tests and check manifest"
task default: ["test:all", "manifest:check"]
