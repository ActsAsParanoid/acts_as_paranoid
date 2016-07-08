require 'active_support/core_ext/array/wrap'

module ActsAsParanoid
  module Validations
    def self.included(base)
      base.extend ClassMethods
    end

    class UniquenessWithoutDeletedValidator
      def self.[](version)
        version = version.to_s
        name = "V#{version.tr('.', '_')}"
        unless constants.include? name.to_sym
          raise "Unknown validator version #{version.inspect}; expected one of #{constants.sort.join(', ')}"
        end
        const_get name
      end

      class V5 < ActiveRecord::Validations::UniquenessValidator
        def validate_each(record, attribute, value)
          finder_class = find_finder_class_for(record)
          table = finder_class.arel_table

          coder = record.class.attribute_types[attribute.to_s]
          value = coder.type_cast_for_schema value if value && coder

          relation = build_relation(finder_class, table, attribute, value)
          [Array(finder_class.primary_key), Array(record.send(:id))].transpose.each do |pk_key, pk_value|
            relation = relation.where(table[pk_key.to_sym].not_eq(pk_value))
          end if record.persisted?

          Array.wrap(options[:scope]).each do |scope_item|
            relation = relation.where(table[scope_item].eq(record.public_send(scope_item)))
          end

          if relation.where(finder_class.paranoid_default_scope).where(relation).exists?
            record.errors.add(attribute, :taken, options.except(:case_sensitive, :scope).merge(:value => value))
          end
        end
      end

      class V4 < ActiveRecord::Validations::UniquenessValidator
        def validate_each(record, attribute, value)
          finder_class = find_finder_class_for(record)
          table = finder_class.arel_table

          # TODO: Use record.class.column_types[attribute.to_s].coder ?
          coder = record.class.column_types[attribute.to_s]

          if value && coder
            value = if coder.respond_to? :type_cast_for_database
                      coder.type_cast_for_database value
                    else
                      coder.type_cast_for_write value
                    end
          end

          relation = build_relation(finder_class, table, attribute, value)
          [Array(finder_class.primary_key), Array(record.send(:id))].transpose.each do |pk_key, pk_value|
            relation = relation.and(table[pk_key.to_sym].not_eq(pk_value))
          end if record.persisted?

          Array.wrap(options[:scope]).each do |scope_item|
            scope_value = record.send(scope_item)
            relation = relation.and(table[scope_item].eq(scope_value))
          end

          # Re-add ActsAsParanoid default scope conditions manually.
          if finder_class.unscoped.where(finder_class.paranoid_default_scope).where(relation).exists?
            record.errors.add(attribute, :taken, options.except(:case_sensitive, :scope).merge(:value => value))
          end
        end
      end
    end

    module ClassMethods
      def validates_uniqueness_of_without_deleted(*attr_names)
        validates_with UniquenessWithoutDeletedValidator[ActiveRecord::VERSION::MAJOR], _merge_attributes(attr_names)
      end
    end
  end
end
