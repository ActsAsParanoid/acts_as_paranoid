print "Using native SQLServer\n"
require 'logger'

ActiveRecord::Base.logger = Logger.new("debug.log")

db1 = 'activerecord_paranoid'

ActiveRecord::Base.establish_connection(
  :adapter  => "sqlserver",
  :host     => "localhost",
  :username => "sa",
  :password => "",
  :database => db1
)
