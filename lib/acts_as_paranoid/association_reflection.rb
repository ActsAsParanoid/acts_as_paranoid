# frozen_string_literal: true

module ActsAsParanoid
  # Override for ActiveRecord::Reflection::AssociationReflection
  module AssociationReflection
    if ActiveRecord::VERSION::MAJOR < 7
      def can_find_inverse_of_automatically?(reflection)
        options = reflection.options

        if reflection.macro == :belongs_to && options[:with_deleted]
          return false if options[:inverse_of] == false
          return false if options[:foreign_key]

          !options.fetch(:original_scope)
        else
          super
        end
      end
    else
      def scope_allows_automatic_inverse_of?(reflection, inverse_reflection)
        if reflection.scope
          options = reflection.options
          return true if options[:with_deleted] && !options.fetch(:original_scope)
        end

        super
      end
    end
  end
end
