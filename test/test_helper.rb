require 'rubygems'
require 'test/unit'
require 'active_support'
require 'active_record'
require 'active_model'

$:.unshift "#{File.dirname(__FILE__)}/../"
$:.unshift "#{File.dirname(__FILE__)}/../lib/"
$:.unshift "#{File.dirname(__FILE__)}/../lib/validations"

require 'init'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :paranoid_times do |t|
      t.column :name, :string
      t.column :deleted_at, :datetime
      t.column :created_at, :datetime      
      t.column :updated_at, :datetime
    end

    create_table :paranoid_booleans do |t|
      t.column :name, :string
      t.column :is_deleted, :boolean
      t.column :created_at, :datetime      
      t.column :updated_at, :datetime
    end

    create_table :not_paranoids do |t|
      t.column :name, :string
      t.column :created_at, :datetime      
      t.column :updated_at, :datetime
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class ParanoidTime < ActiveRecord::Base
  acts_as_paranoid
  validates_uniqueness_of :name
end

class ParanoidBoolean < ActiveRecord::Base
  acts_as_paranoid :column_type => "boolean", :column => "is_deleted"
  validates_uniqueness_of_without_deleted :name
end

class NotParanoid < ActiveRecord::Base
end
