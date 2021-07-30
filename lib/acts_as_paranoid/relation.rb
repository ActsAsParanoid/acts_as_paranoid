# frozen_string_literal: true

module ActsAsParanoid
  module Relation
    def self.included(base)
      base.class_eval do
        def paranoid?
          klass.try(:paranoid?) ? true : false
        end

        def paranoid_deletion_attributes
          { klass.paranoid_column => klass.delete_now_value }
        end

        alias_method :orig_delete_all, :delete_all
        def delete_all!(conditions = nil)
          if conditions
            where(conditions).delete_all!
          else
            orig_delete_all
          end
        end

        def delete_all(conditions = nil)
          if paranoid?
            where(conditions).update_all(paranoid_deletion_attributes)
          else
            delete_all!(conditions)
          end
        end

        def destroy_fully!(id_or_array)
          where(primary_key => id_or_array).orig_delete_all
        end
      end
    end
  end
end
