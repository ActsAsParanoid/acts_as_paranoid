module ActsAsParanoid
  module Associations
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        class << self
          alias_method_chain :belongs_to, :deleted
        end
      end
    end

    module ClassMethods
      def belongs_to_with_deleted(target, options = {})
        with_deleted = options.delete(:with_deleted)
        result = belongs_to_without_deleted(target, options)
      
        if with_deleted
          class_eval <<-RUBY, __FILE__, __LINE__
            def #{target}_with_unscoped(*args)
              return #{target}_without_unscoped(*args) unless #{result.klass}.paranoid?
              #{result.klass}.unscoped { #{target}_without_unscoped(*args) }
            end
            alias_method_chain :#{target}, :unscoped
          RUBY
        end

        result
      end
    end
  end
end
