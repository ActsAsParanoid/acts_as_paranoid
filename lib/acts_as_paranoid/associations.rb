# frozen_string_literal: true

module ActsAsParanoid
  module Associations
    def self.included(base)
      base.extend ClassMethods
      class << base
        alias_method :belongs_to_without_deleted, :belongs_to
        alias_method :belongs_to, :belongs_to_with_deleted

        alias_method :has_one_without_deleted, :has_one
        alias_method :has_one, :has_one_with_deleted
      end
    end

    module ClassMethods
      def belongs_to_with_deleted(target, scope = nil, options = {})
        relation_with_deleted(target, relation: :belongs_to, scope: scope, options: options)
      end

      def has_one_with_deleted(target, scope = nil, options = {})
        relation_with_deleted(target, relation: :has_one, scope: scope, options: options)
      end

      private

      # @param relation [String,Symbol] :belongs_to or :has_one
      def relation_with_deleted(target, relation:, scope: nil, options: {})
        if scope.is_a?(Hash)
          options = scope
          scope = nil
        end

        with_deleted = options.delete(:with_deleted)
        if with_deleted
          original_scope = scope
          scope = make_scope_with_deleted(scope)
        end

        result = send("#{relation}_without_deleted", target, scope, **options)

        if with_deleted
          options = result.values.last.options
          options[:with_deleted] = with_deleted
          options[:original_scope] = original_scope
        end

        result
      end

      def make_scope_with_deleted(scope)
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
              with_deleted
            else
              all
            end
          end
        end

        scope
      end
    end
  end
end
