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

      protected

      def without_paranoid_default_scope
        scope = all

        scope = scope.unscope(where: paranoid_default_scope)
        # Fix problems with unscope group chain
        scope = scope.unscoped if scope.to_sql.include? paranoid_default_scope.to_sql

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
              .delete_all!(Hash[[Array(self.class.primary_key), Array(id)].transpose])
            decrement_counters_on_associations
          end

          stale_paranoid_value
          @destroyed = true
          freeze
        end
      end
    end

    def destroy!
      if !deleted?
        with_transaction_returning_status do
          run_callbacks :destroy do
            if persisted?
              # Handle composite keys, otherwise we would just use
              # `self.class.primary_key.to_sym => self.id`.
              self.class
                .delete_all(Hash[[Array(self.class.primary_key), Array(id)].transpose])
              decrement_counters_on_associations
            end

            @_trigger_destroy_callback = true

            stale_paranoid_value
            self
          end
        end
      else
        destroy_fully! if paranoid_configuration[:double_tap_destroys_fully]
      end
    end

    alias destroy destroy!

    def recover(options = {})
      return if !deleted?

      options = {
        recursive: self.class.paranoid_configuration[:recover_dependent_associations],
        recovery_window: self.class.paranoid_configuration[:dependent_recovery_window],
        raise_error: false
      }.merge(options)

      self.class.transaction do
        run_callbacks :recover do
          if options[:recursive]
            recover_dependent_associations(options[:recovery_window], options)
          end
          increment_counters_on_associations
          self.paranoid_value = self.class.paranoid_configuration[:recovery_value]
          if options[:raise_error]
            save!
          else
            save
          end
        end
      end
    end

    def recover!(options = {})
      options[:raise_error] = true

      recover(options)
    end

    def recover_dependent_associations(window, options)
      self.class.dependent_associations.each do |reflection|
        next unless (klass = get_reflection_class(reflection)).paranoid?

        scope = klass.only_deleted.merge(get_association_scope(reflection: reflection))

        # We can only recover by window if both parent and dependant have a
        # paranoid column type of :time.
        if self.class.paranoid_column_type == :time && klass.paranoid_column_type == :time
          scope = scope.deleted_inside_time_window(paranoid_value, window)
        end

        scope.each do |object|
          object.recover(options)
        end
      end
    end

    def destroy_dependent_associations!
      self.class.dependent_associations.each do |reflection|
        next unless (klass = get_reflection_class(reflection)).paranoid?

        klass
          .only_deleted.merge(get_association_scope(reflection: reflection))
          .each(&:destroy!)
      end
    end

    def deleted?
      @destroyed || !if self.class.string_type_with_deleted_value?
                       paranoid_value != self.class.delete_now_value || paranoid_value.nil?
                     elsif self.class.boolean_type_not_nullable?
                       paranoid_value == false
                     else
                       paranoid_value.nil?
                     end
    end

    alias destroyed? deleted?

    def deleted_fully?
      @destroyed
    end

    alias destroyed_fully? deleted_fully?

    private

    def get_association_scope(reflection:)
      ActiveRecord::Associations::AssociationScope.scope(association(reflection.name))
    end

    def get_reflection_class(reflection)
      if reflection.macro == :belongs_to && reflection.options.include?(:polymorphic)
        send(reflection.foreign_type).constantize
      else
        reflection.klass
      end
    end

    def paranoid_value=(value)
      write_attribute(self.class.paranoid_column, value)
    end

    def update_counters_on_associations(method_sym)
      return unless [:decrement_counter, :increment_counter].include? method_sym

      each_counter_cached_association_reflection do |assoc_reflection|
        next unless associated_object = send(assoc_reflection.name)

        counter_cache_column = assoc_reflection.counter_cache_column
        associated_object.class.send(method_sym, counter_cache_column,
                                     associated_object.id)
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
