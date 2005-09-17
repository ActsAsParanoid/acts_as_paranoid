$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rubygems'
require 'test/unit'
require 'active_record'
require 'active_record/fixtures'
require 'active_support/binding_of_caller'
require 'active_support/breakpoint'
require 'connection'
require 'acts_as_paranoid'

class Test::Unit::TestCase #:nodoc:
  def create_fixtures(*table_names)
    if block_given?
      Fixtures.create_fixtures(File.dirname(__FILE__) + "/fixtures/", table_names) { yield }
    else
      Fixtures.create_fixtures(File.dirname(__FILE__) + "/fixtures/", table_names)
    end
  end
end

Test::Unit::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
Test::Unit::TestCase.use_instantiated_fixtures = false
Test::Unit::TestCase.use_transactional_fixtures = (ENV['AR_TX_FIXTURES'] == "yes")

