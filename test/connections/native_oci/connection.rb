print "Using OCI Oracle\n"
require 'logger'

ActiveRecord::Base.logger = Logger.new STDOUT
ActiveRecord::Base.logger.level = Logger::WARN

db1 = 'activerecord_paranoid'

ActiveRecord::Base.establish_connection(
  :adapter  => 'oci',
  :host     => '',          # can use an oracle SID
  :username => 'arunit',
  :password => 'arunit',
  :database => db1
)
