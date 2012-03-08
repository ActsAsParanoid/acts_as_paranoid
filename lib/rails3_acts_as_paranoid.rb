require 'active_record/base'
require 'active_record/relation'
require 'active_record/callbacks'
require 'acts_as_paranoid/core'
require 'acts_as_paranoid/associations'
require 'acts_as_paranoid/validations'
require 'acts_as_paranoid/relation'


module ActsAsParanoid
  
  def paranoid?
    self.included_modules.include?(ActsAsParanoid::Core)
  end
  
  def validates_as_paranoid
    include ActsAsParanoid::Validations
  end
  
  def acts_as_paranoid(options = {})
    raise ArgumentError, "Hash expected, got #{options.class.name}" if not options.is_a?(Hash) and not options.empty?
    
    class_attribute :paranoid_configuration, :paranoid_column_reference
    
    self.paranoid_configuration = { :column => "deleted_at", :column_type => "time", :recover_dependent_associations => true, :dependent_recovery_window => 2.minutes }
    self.paranoid_configuration.merge!({ :deleted_value => "deleted" }) if options[:column_type] == "string"
    self.paranoid_configuration.merge!(options) # user options

    raise ArgumentError, "'time', 'boolean' or 'string' expected for :column_type option, got #{paranoid_configuration[:column_type]}" unless ['time', 'boolean', 'string'].include? paranoid_configuration[:column_type]

    self.paranoid_column_reference = "#{self.table_name}.#{paranoid_configuration[:column]}"
    
    return if paranoid?

    # Magic!
    default_scope { where(paranoid_default_scope_sql) }

    scope :paranoid_deleted_around_time, lambda {|value, window|
      if self.class.respond_to?(:paranoid?) && self.class.paranoid?
        if self.class.paranoid_column_type == 'time' && ![true, false].include?(value)
          self.where("#{self.class.paranoid_column} > ? AND #{self.class.paranoid_column} < ?", (value - window), (value + window))
        else
          self.only_deleted
        end
      end if paranoid_configuration[:column_type] == 'time'
    }
    
    include ActsAsParanoid::Core
    include ActsAsParanoid::Associations
  end
end

# Extend ActiveRecord's functionality
ActiveRecord::Base.send :extend, ActsAsParanoid

# Override ActiveRecord::Relation's behavior
ActiveRecord::Relation.send :include, ActsAsParanoid::Relation

# Push the recover callback onto the activerecord callback list
ActiveRecord::Callbacks::CALLBACKS.push(:before_recover, :after_recover)
