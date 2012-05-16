module ActsAsParanoid
  module Associations
    def self.included(base)
      base.extend ClassMethods
      class << base
        alias_method_chain :belongs_to, :deleted
      end
    end

    module ClassMethods
      def belongs_to_with_deleted(target, options = {})
        with_deleted = options.delete(:with_deleted)
        result = belongs_to_without_deleted(target, options)

        if with_deleted
          result.options[:with_deleted] = with_deleted
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

        result
      end
    end
  end
end
