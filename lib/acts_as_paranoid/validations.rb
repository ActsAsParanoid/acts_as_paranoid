# frozen_string_literal: true

require "active_support/core_ext/array/wrap"

module ActsAsParanoid
  module Validations
    def self.included(base)
      base.extend ClassMethods
    end

    class UniquenessWithoutDeletedValidator < ActiveRecord::Validations::UniquenessValidator
      private

      def build_relation(klass, attribute, value)
        super.where(klass.paranoid_default_scope)
      end
    end

    module ClassMethods
      def validates_uniqueness_of_without_deleted(*attr_names)
        validates_with UniquenessWithoutDeletedValidator, _merge_attributes(attr_names)
      end
    end
  end
end
