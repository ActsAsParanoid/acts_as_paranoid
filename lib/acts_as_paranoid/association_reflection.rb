# frozen_string_literal: true

module ActsAsParanoid
  # Override for ActiveRecord::Reflection::AssociationReflection
  #
  # This makes automatic finding of inverse associations work where the
  # inverse is a belongs_to association with the :with_deleted option set.
  #
  # Specifying :with_deleted for the belongs_to association would stop the
  # inverse from being calculated because it sets scope where there was none,
  # and normally an association having a scope means ActiveRecord will not
  # automatically find the inverse association.
  #
  # This override adds an exception to that rule only for the case where the
  # scope was added just to support the :with_deleted option.
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
