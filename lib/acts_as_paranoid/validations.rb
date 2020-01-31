# frozen_string_literal: true

require "active_support/core_ext/array/wrap"

module ActsAsParanoid
  module Validations
    def self.included(base)
      base.extend ClassMethods
    end

    class UniquenessWithoutDeletedValidator < ActiveRecord::Validations::UniquenessValidator
      def validate_each(record, attribute, value)
        finder_class = find_finder_class_for(record)
        table = finder_class.arel_table

        relation = build_relation(finder_class, attribute, value)
        if record.persisted?
          [Array(finder_class.primary_key), Array(record.send(:id))]
            .transpose
            .each do |pk_key, pk_value|
            relation = relation.where(table[pk_key.to_sym].not_eq(pk_value))
          end
        end

        Array.wrap(options[:scope]).each do |scope_item|
          relation = relation.where(table[scope_item].eq(record.public_send(scope_item)))
        end

        if relation.where(finder_class.paranoid_default_scope).exists?(relation)
          record.errors.add(attribute,
                            :taken,
                            options.except(:case_sensitive, :scope).merge(value: value))
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
