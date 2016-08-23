module ActsAsParanoid
  module Associations
    def self.included(base)
      class << base
        prepend(ClassMethods)
      end
    end

    module ClassMethods
      def belongs_to(target, scope = nil, options = {})
        with_deleted = (scope.is_a?(Hash) ? scope : options).delete(:with_deleted)
        result = super(target, scope, options)

        if with_deleted
          if result.is_a? Hash
            result.values.last.options[:with_deleted] = with_deleted
          else
            result.options[:with_deleted] = with_deleted
          end

          # Grab unbound instance method from super above
          original_method = instance_method(target.to_sym)

          # Define new accessor that honors the paranoid logic
          define_method(target) do |*args|
            association = association(target.to_sym)
            return nil if association.options[:polymorphic] && association.klass.nil?
            return original_method.bind(self).call(*args) unless association.klass.paranoid?
            association.klass.with_deleted.scoping { original_method.bind(self).call(*args) }
          end
        end

        result
      end
    end
  end
end
