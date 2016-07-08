require 'acts_as_paranoid/core'
require 'acts_as_paranoid/associations'
require 'acts_as_paranoid/validations'
require 'acts_as_paranoid/relation'
require 'acts_as_paranoid/preloader_association'

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
    self.paranoid_configuration.merge!({ :allow_nulls => true }) if options[:column_type] == "boolean"
    self.paranoid_configuration.merge!(options) # user options

    raise ArgumentError, "'time', 'boolean' or 'string' expected for :column_type option, got #{paranoid_configuration[:column_type]}" unless ['time', 'boolean', 'string'].include? paranoid_configuration[:column_type]

    self.paranoid_column_reference = "#{self.table_name}.#{paranoid_configuration[:column]}"

    return if paranoid?

    include ActsAsParanoid::Core

    # Magic!
    default_scope { where(paranoid_default_scope) }

    if paranoid_configuration[:column_type] == 'time'
      scope :deleted_inside_time_window, lambda {|time, window|
        deleted_after_time((time - window)).deleted_before_time((time + window))
      }

      scope :deleted_after_time, lambda  { |time| where("#{self.table_name}.#{paranoid_column} > ?", time) }
      scope :deleted_before_time, lambda { |time| where("#{self.table_name}.#{paranoid_column} < ?", time) }
    end
  end
end

# Extend ActiveRecord's functionality
ActiveRecord::Base.send :extend, ActsAsParanoid

# Extend ActiveRecord::Base with paranoid associations
ActiveRecord::Base.send :include, ActsAsParanoid::Associations

# Override ActiveRecord::Relation's behavior
ActiveRecord::Relation.send :include, ActsAsParanoid::Relation

# Push the recover callback onto the activerecord callback list
ActiveRecord::Callbacks::CALLBACKS.push(:before_recover, :after_recover)

# Use with_deleted in preloader build_scope
ActiveRecord::Associations::Preloader::Association.send :include, ActsAsParanoid::PreloaderAssociation
