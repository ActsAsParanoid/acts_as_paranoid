# frozen_string_literal: true

module ActsAsParanoid
  module Core
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def self.extended(base)
        base.define_callbacks :recover
      end

      def before_recover(method)
        set_callback :recover, :before, method
      end

      def after_recover(method)
        set_callback :recover, :after, method
      end

      def with_deleted
        without_paranoid_default_scope
      end

      def only_deleted
        if string_type_with_deleted_value?
          without_paranoid_default_scope
            .where(paranoid_column_reference => paranoid_configuration[:deleted_value])
        elsif boolean_type_not_nullable?
          without_paranoid_default_scope.where(paranoid_column_reference => true)
        else
          without_paranoid_default_scope.where.not(paranoid_column_reference => nil)
        end
      end

      def delete_all!(conditions = nil)
        without_paranoid_default_scope.delete_all!(conditions)
      end

      def delete_all(conditions = nil)
        where(conditions)
          .update_all(["#{paranoid_configuration[:column]} = ?", delete_now_value])
      end

      def paranoid_default_scope
        if string_type_with_deleted_value?
          all.table[paranoid_column].eq(nil)
            .or(all.table[paranoid_column].not_eq(paranoid_configuration[:deleted_value]))
        elsif boolean_type_not_nullable?
          all.table[paranoid_column].eq(false)
        else
          all.table[paranoid_column].eq(nil)
        end
      end

      def string_type_with_deleted_value?
        paranoid_column_type == :string && !paranoid_configuration[:deleted_value].nil?
      end

      def boolean_type_not_nullable?
        paranoid_column_type == :boolean && !paranoid_configuration[:allow_nulls]
      end

      def paranoid_column
        paranoid_configuration[:column].to_sym
      end

      def paranoid_column_type
        paranoid_configuration[:column_type].to_sym
      end

      def paranoid_column_reference
        "#{table_name}.#{paranoid_column}"
      end

      def dependent_associations
        reflect_on_all_associations.select do |a|
          [:destroy, :delete_all].include?(a.options[:dependent])
        end
      end

      def delete_now_value
        case paranoid_configuration[:column_type]
        when "time" then Time.now
        when "boolean" then true
        when "string" then paranoid_configuration[:deleted_value]
        end
      end

      def recovery_value
        if boolean_type_not_nullable?
          false
        else
          nil
        end
      end

      protected

      def define_deleted_time_scopes
        scope :deleted_inside_time_window, lambda { |time, window|
          deleted_after_time((time - window)).deleted_before_time((time + window))
        }

        scope :deleted_after_time, lambda { |time|
          only_deleted
            .where("#{table_name}.#{paranoid_column} > ?", time)
        }
        scope :deleted_before_time, lambda { |time|
          only_deleted
            .where("#{table_name}.#{paranoid_column} < ?", time)
        }
      end

      def without_paranoid_default_scope
        scope = all

        # unscope avoids applying the default scope when using this scope for associations
        scope = scope.unscope(where: paranoid_column)

        paranoid_where_clause =
          ActiveRecord::Relation::WhereClause.new([paranoid_default_scope])

        scope.where_clause = all.where_clause - paranoid_where_clause

        scope
      end
    end

    def persisted?
      !(new_record? || @destroyed)
    end

    def paranoid_value
      send(self.class.paranoid_column)
    end

    # Straight from ActiveRecord 5.1!
    def delete
      self.class.delete(id) if persisted?
      stale_paranoid_value
      freeze
    end

    def destroy_fully!
      with_transaction_returning_status do
        run_callbacks :destroy do
          destroy_dependent_associations!

          if persisted?
            # Handle composite keys, otherwise we would just use
            # `self.class.primary_key.to_sym => self.id`.
            self.class
              .delete_all!([Array(self.class.primary_key), Array(id)].transpose.to_h)
            decrement_counters_on_associations
          end

          @destroyed = true
          freeze
        end
      end
    end

    def destroy!
      destroy || raise(
        ActiveRecord::RecordNotDestroyed.new("Failed to destroy the record", self)
      )
    end

    def destroy
      if !deleted?
        with_transaction_returning_status do
          run_callbacks :destroy do
            if persisted?
              # Handle composite keys, otherwise we would just use
              # `self.class.primary_key.to_sym => self.id`.
              self.class
                .delete_all([Array(self.class.primary_key), Array(id)].transpose.to_h)
              decrement_counters_on_associations
            end

            @_trigger_destroy_callback = true

            stale_paranoid_value
            self
          end
        end
      elsif paranoid_configuration[:double_tap_destroys_fully]
        destroy_fully!
      end
    end

    def recover(options = {})
      return if !deleted?

      options = {
        recursive: self.class.paranoid_configuration[:recover_dependent_associations],
        recovery_window: self.class.paranoid_configuration[:dependent_recovery_window],
        raise_error: false
      }.merge(options)

      self.class.transaction do
        run_callbacks :recover do
          increment_counters_on_associations
          deleted_value = paranoid_value
          self.paranoid_value = self.class.recovery_value
          result = if options[:raise_error]
                     save!
                   else
                     save
                   end
          recover_dependent_associations(deleted_value, options) if options[:recursive]
          result
        end
      end
    end

    def recover!(options = {})
      options[:raise_error] = true

      recover(options)
    end

    def deleted?
      return true if @destroyed

      if self.class.string_type_with_deleted_value?
        paranoid_value == paranoid_configuration[:deleted_value]
      elsif self.class.boolean_type_not_nullable?
        paranoid_value == true
      else
        !paranoid_value.nil?
      end
    end

    alias destroyed? deleted?

    def deleted_fully?
      @destroyed
    end

    alias destroyed_fully? deleted_fully?

    private

    def recover_dependent_associations(deleted_value, options)
      self.class.dependent_associations.each do |reflection|
        recover_dependent_association(reflection, deleted_value, options)
      end
    end

    def destroy_dependent_associations!
      self.class.dependent_associations.each do |reflection|
        assoc = association(reflection.name)
        next unless (klass = assoc.klass).paranoid?

        klass
          .only_deleted.merge(get_association_scope(assoc))
          .each(&:destroy!)
      end
    end

    def recover_dependent_association(reflection, deleted_value, options)
      assoc = association(reflection.name)
      return unless (klass = assoc.klass).paranoid?

      if reflection.belongs_to? && attributes[reflection.association_foreign_key].nil?
        return
      end

      scope = klass.only_deleted.merge(get_association_scope(assoc))

      # We can only recover by window if both parent and dependant have a
      # paranoid column type of :time.
      if self.class.paranoid_column_type == :time && klass.paranoid_column_type == :time
        scope = scope.deleted_inside_time_window(deleted_value, options[:recovery_window])
      end

      recovered = false
      scope.each do |object|
        object.recover(options)
        recovered = true
      end

      assoc.reload if recovered && reflection.has_one? && assoc.loaded?
    end

    def get_association_scope(dependent_association)
      ActiveRecord::Associations::AssociationScope.scope(dependent_association)
    end

    def paranoid_value=(value)
      write_attribute(self.class.paranoid_column, value)
    end

    def update_counters_on_associations(method_sym)
      each_counter_cached_association_reflection do |assoc_reflection|
        reflection_options = assoc_reflection.options
        next unless reflection_options[:counter_cache]

        associated_object = send(assoc_reflection.name)
        next unless associated_object

        counter_cache_column = assoc_reflection.counter_cache_column
        associated_object.class.send(method_sym, counter_cache_column,
                                     associated_object.id)
        associated_object.touch if reflection_options[:touch]
      end
    end

    def each_counter_cached_association_reflection
      _reflections.each do |_name, reflection|
        yield reflection if reflection.belongs_to? && reflection.counter_cache_column
      end
    end

    def increment_counters_on_associations
      update_counters_on_associations :increment_counter
    end

    def decrement_counters_on_associations
      update_counters_on_associations :decrement_counter
    end

    def stale_paranoid_value
      self.paranoid_value = self.class.delete_now_value
      clear_attribute_changes([self.class.paranoid_column])
    end
  end
end
