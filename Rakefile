require 'rubygems'

Gem::manage_gems

require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/testtask'
require 'rake/contrib/rubyforgepublisher'

PKG_NAME      = 'acts_as_paranoid'
PKG_VERSION   = '0.1.3'
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"
PROD_HOST     = "technoweenie@bidwell.textdrive.com"

for adapter in %w( mysql postgresql sqlite sqlite3 sqlserver sqlserver_odbc db2 oci )
  Rake::TestTask.new("test_#{adapter}") do |t|
    t.libs << "test" << "test/connections/native_#{adapter}"
    t.pattern = "test/*_test{,_#{adapter}}.rb"
    t.verbose = true
  end
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "#{PKG_NAME} -- painless encryption for Active Record"
  rdoc.options << '--line-numbers --inline-source --accessor cattr_accessor=object'
  rdoc.template = "#{ENV['template']}.rb" if ENV['template']
  rdoc.rdoc_files.include('README', 'CHANGELOG', 'RUNNING_UNIT_TESTS')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

spec = Gem::Specification.new do |s|
  s.name            = PKG_NAME
  s.version         = PKG_VERSION
  s.platform        = Gem::Platform::RUBY
  s.summary         = "acts_as_paranoid keeps models from actually being deleted by setting a deleted_at field."
  s.files           = FileList["{lib,test}/**/*"].to_a + %w(README MIT-LICENSE CHANGELOG RUNNING_UNIT_TESTS)
  s.files.delete      "test/fixtures/activerecord_paranoid.sqlite"
  s.files.delete      "test/fixtures/activerecord_paranoid.sqlite3"
  s.require_path    = 'lib'
  s.autorequire     = 'acts_as_paranoid'
  s.has_rdoc        = true
  s.test_file       = 'test/tests.rb'
  s.author          = "Rick Olson"
  s.email           = "technoweenie@gmail.com"
  s.homepage        = "http://techno-weenie.net"
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end

desc "Publish the gem"
task :pgem => [:package] do 
  Rake::SshFilePublisher.new(PROD_HOST, "public_html/code/gems", "pkg", "#{PKG_FILE_NAME}.gem").upload
  Rake::SshFilePublisher.new(PROD_HOST, "public_html/code/pkg", "pkg", "#{PKG_FILE_NAME}.tgz").upload
  %x{ssh #{PROD_HOST} 'update_gems'}
end

desc "Publish the API documentation"
task :pdoc => [:rdoc] do 
  Rake::SshDirPublisher.new(PROD_HOST, "public_html/code/doc/#{PKG_NAME}", "doc").upload
end

desc 'Publish the gem and API docs'
task :publish => [:pgem, :pdoc]