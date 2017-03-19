module ActsAsParanoid
  module PreloaderAssociation
    def self.included(base)
      base.class_eval do
        prepend(PrependedMethods)
      end
    end

    module PrependedMethods
      def build_scope
        scope = super
        scope = scope.with_deleted if options[:with_deleted] && klass.respond_to?(:with_deleted)
        scope
      end
    end
  end
end
