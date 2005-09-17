print "Using native DB2\n"
require 'logger'

ActiveRecord::Base.logger = Logger.new("debug.log")

db1 = 'arparanoid'

ActiveRecord::Base.establish_connection(
  :adapter  => "db2",
  :host     => "localhost",
  :username => "arunit",
  :password => "arunit",
  :database => db1
)
