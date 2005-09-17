$:.unshift "../lib"
Dir["**/*_test.rb"].each { |f| load f }