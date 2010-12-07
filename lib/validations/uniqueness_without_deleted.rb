require 'active_support/core_ext/array/wrap'

module ParanoidValidations
  class UniquenessWithoutDeletedValidator < ActiveRecord::Validations::UniquenessValidator
    def validate_each(record, attribute, value)
      finder_class = find_finder_class_for(record)

      if value && record.class.serialized_attributes.key?(attribute.to_s)
        value = YAML.dump value
      end

      sql, params = mount_sql_and_params(finder_class, record.class.quoted_table_name, attribute, value)

      # This is the only changed line from the base class version - it does finder_class.unscoped
      relation = finder_class.where(sql, *params)
      
      Array.wrap(options[:scope]).each do |scope_item|
        scope_value = record.send(scope_item)
        relation = relation.where(scope_item => scope_value)
      end

      if record.persisted?
        # TODO : This should be in Arel
        relation = relation.where("#{record.class.quoted_table_name}.#{record.class.primary_key} <> ?", record.send(:id))
      end

      if relation.exists?
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
