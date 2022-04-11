# frozen_string_literal: true

module ActsAsParanoid
  # Override for ActiveRecord::Reflection::AssociationReflection
  module AssociationReflection
    def scope_allows_automatic_inverse_of?(reflection, inverse_reflection)
      if reflection.scope
        options = reflection.options
        return true if options[:with_deleted] && !options.fetch(:original_scope)
      end

      super
    end
  end
end
