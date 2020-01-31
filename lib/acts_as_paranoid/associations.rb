module ActsAsParanoid
  module Associations
    def self.included(base)
      base.extend ClassMethods
      class << base
        alias_method :belongs_to_without_deleted, :belongs_to
        alias_method :belongs_to, :belongs_to_with_deleted
      end
    end

    module ClassMethods
      def belongs_to_with_deleted(target, scope = nil, options = {})
        if scope.is_a?(Hash)
          options = scope
          scope = nil
        end

        with_deleted = options.delete(:with_deleted)
        if with_deleted
          if scope
            old_scope = scope
            scope = proc do |*args|
              if old_scope.arity == 0
                instance_exec(&old_scope).with_deleted
              else
                old_scope.call(*args).with_deleted
              end
            end
          else
            scope = proc do
              if respond_to? :with_deleted
                self.with_deleted
              else
                self.all
              end
            end
          end
        end

        result = belongs_to_without_deleted(target, scope, options)

        if with_deleted
          result.values.last.options[:with_deleted] = with_deleted
        end

        result
      end
    end
  end
end
