module ActsAsParanoid
  module Associations
    def self.included(base)
      base.extend ClassMethods
      class << base
        alias_method_chain :belongs_to, :deleted
      end
    end

    module ClassMethods
      def belongs_to_with_deleted(target, scope = nil, options = {})
        with_deleted = (scope.is_a?(Hash) ? scope : options).delete(:with_deleted)
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
              alias_method_chain :#{target}, :unscoped
            RUBY
          end
        end

        result
      end
    end
  end
end
