require 'active_support/core_ext/array/wrap'

module ActsAsParanoid
  module Validations
    def self.included(base)
      base.extend ClassMethods
    end

    class UniquenessWithoutDeletedValidator < ActiveRecord::Validations::UniquenessValidator
      def validate_each(record, attribute, value)
        finder_class = find_finder_class_for(record)
        table = finder_class.arel_table

        coder = record.class.serialized_attributes[attribute.to_s]

        if value && coder
          value = coder.dump value
        end

        relation = build_relation(finder_class, table, attribute, value)
        relation = relation.and(table[finder_class.primary_key.to_sym].not_eq(record.send(:id))) if record.persisted?

        Array.wrap(options[:scope]).each do |scope_item|
          scope_value = record.send(scope_item)
          relation = relation.and(table[scope_item].eq(scope_value))
        end

        # Re-add ActsAsParanoid default scope conditions manually.
        if finder_class.unscoped.where(finder_class.paranoid_default_scope_sql).where(relation).exists?
          record.errors.add(attribute, :taken, options.except(:case_sensitive, :scope).merge(:value => value))
        end
      end
    end

    module ClassMethods
      def validates_uniqueness_of_without_deleted(*attr_names)
        validates_with UniquenessWithoutDeletedValidator, _merge_attributes(attr_names)
      end
    end
  end
end
