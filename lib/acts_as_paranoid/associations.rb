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
        result = belongs_to_without_deleted(target, scope, options)

        if with_deleted
          if result.is_a? Hash
            result.values.last.options[:with_deleted] = with_deleted
          else
            result.options[:with_deleted] = with_deleted
          end

          unless method_defined? "#{target}_with_unscoped"
            class_eval <<-RUBY, __FILE__, __LINE__
              def #{target}_with_unscoped(*args)
                association = association(:#{target})
                return nil if association.options[:polymorphic] && association.klass.nil?
                return #{target}_without_unscoped(*args) unless association.klass.paranoid?
                association.klass.with_deleted.scoping { #{target}_without_unscoped(*args) }
              end
              alias_method :#{target}_without_unscoped, :#{target}
              alias_method :#{target}, :#{target}_with_unscoped
            RUBY
          end
        end

        result
      end
    end
  end
end
