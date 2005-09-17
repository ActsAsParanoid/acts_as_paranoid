print "Using native SQLServer via ODBC\n"
require 'logger'

ActiveRecord::Base.logger = Logger.new("debug.log")

dsn1 = 'activerecord_paranoid'

ActiveRecord::Base.establish_connection(
  :adapter  => "sqlserver",
  :mode     => "ODBC",
  :host     => "localhost",
  :username => "sa",
  :password => "",
  :dsn => dsn1
)
