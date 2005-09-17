print "Using native PostgreSQL\n"
require 'logger'

ActiveRecord::Base.logger = Logger.new("debug.log")

db1 = 'activerecord_paranoid'

ActiveRecord::Base.establish_connection(
  :adapter  => "postgresql",
  :host     => nil, 
  :username => "postgres",
  :password => "postgres", 
  :database => db1
)