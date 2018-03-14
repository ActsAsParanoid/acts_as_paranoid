module ActsAsParanoid
  module PreloaderAssociation
    def self.included(base)
      base.class_eval do
        def build_scope_with_deleted
          scope = build_scope_without_deleted
          scope = scope.with_deleted if reflection.options[:with_deleted] && klass.respond_to?(:with_deleted)
          scope
        end

        alias_method :build_scope_without_deleted, :build_scope
        alias_method :build_scope, :build_scope_with_deleted
      end
    end
  end
end
