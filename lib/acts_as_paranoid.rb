# frozen_string_literal: true

require "active_record"
require "acts_as_paranoid/core"
require "acts_as_paranoid/associations"
require "acts_as_paranoid/validations"
require "acts_as_paranoid/relation"
require "acts_as_paranoid/association_reflection"

module ActsAsParanoid
  def paranoid?
    included_modules.include?(ActsAsParanoid::Core)
  end

  def validates_as_paranoid
    include ActsAsParanoid::Validations
  end

  def acts_as_paranoid(options = {})
    if !options.is_a?(Hash) && !options.empty?
      raise ArgumentError, "Hash expected, got #{options.class.name}"
    end

    class_attribute :paranoid_configuration

    self.paranoid_configuration = {
      column: "deleted_at",
      column_type: "time",
      recover_dependent_associations: true,
      dependent_recovery_window: 2.minutes,
      double_tap_destroys_fully: true
    }
    if options[:column_type] == "string"
      paranoid_configuration.merge!(deleted_value: "deleted")
    end

    paranoid_configuration.merge!(options) # user options

    unless %w[time boolean string].include? paranoid_configuration[:column_type]
      raise ArgumentError,
            "'time', 'boolean' or 'string' expected for :column_type option," \
            " got #{paranoid_configuration[:column_type]}"
    end

    return if paranoid?

    include ActsAsParanoid::Core

    # Magic!
    default_scope { where(paranoid_default_scope) }

    define_deleted_time_scopes if paranoid_column_type == :time
  end
end

# Extend ActiveRecord's functionality
ActiveRecord::Base.extend ActsAsParanoid

# Extend ActiveRecord::Base with paranoid associations
ActiveRecord::Base.include ActsAsParanoid::Associations

# Override ActiveRecord::Relation's behavior
ActiveRecord::Relation.include ActsAsParanoid::Relation

# Push the recover callback onto the activerecord callback list
ActiveRecord::Callbacks::CALLBACKS.push(:before_recover, :after_recover)

ActiveRecord::Reflection::AssociationReflection
  .prepend ActsAsParanoid::AssociationReflection
