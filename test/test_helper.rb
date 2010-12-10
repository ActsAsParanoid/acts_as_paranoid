require 'rubygems'
require 'test/unit'
require 'active_support'
require 'active_record'

$:.unshift "#{File.dirname(__FILE__)}/../lib/"
require 'rails3_acts_as_paranoid'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :paranoid_times do |t|
      t.string    :name
      t.datetime  :deleted_at
      t.integer   :paranoid_belongs_dependant_id

      t.integer   :not_paranoid_id

      t.timestamps
    end

    create_table :paranoid_booleans do |t|
      t.string    :name
      t.boolean   :is_deleted
      t.integer   :paranoid_time_id

      t.timestamps
    end

    create_table :not_paranoids do |t|
      t.string    :name

      t.integer   :paranoid_time_id

      t.timestamps
    end

    create_table :has_one_not_paranoids do |t|
      t.string    :name

      t.integer   :paranoid_time_id

      t.timestamps
    end

    create_table :paranoid_has_many_dependants do |t|
      t.string    :name
      t.datetime  :deleted_at
      t.integer   :paranoid_time_id
      t.integer   :paranoid_belongs_dependant_id

      t.timestamps
    end

    create_table :paranoid_belongs_dependants do |t|
      t.string    :name
      t.datetime  :deleted_at

      t.timestamps
    end

    create_table :paranoid_has_one_dependants do |t|
      t.string    :name
      t.datetime  :deleted_at
      t.integer   :paranoid_boolean_id

      t.timestamps
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

  has_many :paranoid_has_many_dependants, :dependent => :destroy
  has_many :paranoid_booleans, :dependent => :destroy
  has_many :not_paranoids, :dependent => :destroy

  has_one :has_one_not_paranoid, :dependent => :destroy

  belongs_to :not_paranoid, :dependent => :destroy
end

class ParanoidBoolean < ActiveRecord::Base
  acts_as_paranoid :column_type => "boolean", :column => "is_deleted"

  belongs_to :paranoid_time
  has_one :paranoid_has_one_dependant, :dependent => :destroy
end

class NotParanoid < ActiveRecord::Base
end

class HasOneNotParanoid < ActiveRecord::Base
end

class ParanoidHasManyDependant < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :paranoid_time

  belongs_to :paranoid_belongs_dependant, :dependent => :destroy
end

class ParanoidBelongsDependant < ActiveRecord::Base
  acts_as_paranoid

  has_many :paranoid_has_many_dependants
end

class ParanoidHasOneDependant < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :paranoid_boolean
end
