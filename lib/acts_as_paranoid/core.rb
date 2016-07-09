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
          without_paranoid_default_scope.where(paranoid_column_reference => paranoid_configuration[:deleted_value])
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
        where(conditions).update_all(["#{paranoid_configuration[:column]} = ?", delete_now_value])
      end

      def paranoid_default_scope
        if string_type_with_deleted_value?
          self.all.table[paranoid_column].eq(nil).
            or(self.all.table[paranoid_column].not_eq(paranoid_configuration[:deleted_value]))
        elsif boolean_type_not_nullable?
          self.all.table[paranoid_column].eq(false)
        else
          self.all.table[paranoid_column].eq(nil)
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
        self.reflect_on_all_associations.select {|a| [:destroy, :delete_all].include?(a.options[:dependent]) }
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
        scope = self.all

        if ActiveRecord::VERSION::MAJOR < 5
          # ActiveRecord 4.0.*
          scope = scope.with_default_scope if ActiveRecord::VERSION::MINOR < 1
          scope.where_values.delete(paranoid_default_scope)
        else
          scope = scope.unscope(where: paranoid_default_scope)
          # Fix problems with unscope group chain
          scope = scope.unscoped if scope.to_sql.include? paranoid_default_scope.to_sql
        end

        scope
      end
    end

    def persisted?
      !(new_record? || @destroyed)
    end

    def paranoid_value
      self.send(self.class.paranoid_column)
    end

    def destroy_fully!
      with_transaction_returning_status do
        run_callbacks :destroy do
          destroy_dependent_associations!
          # Handle composite keys, otherwise we would just use `self.class.primary_key.to_sym => self.id`.
          self.class.delete_all!(Hash[[Array(self.class.primary_key), Array(self.id)].transpose]) if persisted?
          self.paranoid_value = self.class.delete_now_value
          freeze
        end
      end
    end

    def destroy!
      if !deleted?
        with_transaction_returning_status do
          run_callbacks :destroy do
            # Handle composite keys, otherwise we would just use `self.class.primary_key.to_sym => self.id`.
            self.class.delete_all(Hash[[Array(self.class.primary_key), Array(self.id)].transpose]) if persisted?
            self.paranoid_value = self.class.delete_now_value
            self
          end
        end
      else
        destroy_fully!
      end
    end

    alias_method :destroy, :destroy!

    def recover(options={})
      options = {
        :recursive => self.class.paranoid_configuration[:recover_dependent_associations],
        :recovery_window => self.class.paranoid_configuration[:dependent_recovery_window]
      }.merge(options)

      self.class.transaction do
        run_callbacks :recover do
          recover_dependent_associations(options[:recovery_window], options) if options[:recursive]

          self.paranoid_value = nil
          self.save
        end
      end
    end

    def recover_dependent_associations(window, options)
      self.class.dependent_associations.each do |reflection|
        next unless (klass = get_reflection_class(reflection)).paranoid?

        scope = klass.only_deleted

        # Merge in the association's scope
        scope = scope.merge(association(reflection.name).association_scope)

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

        scope = klass.only_deleted

        # Merge in the association's scope
        scope = scope.merge(association(reflection.name).association_scope)

        scope.each do |object|
          object.destroy!
        end
      end
    end

    def deleted?
      !if self.class.string_type_with_deleted_value?
        paranoid_value != self.class.delete_now_value || paranoid_value.nil?
      elsif self.class.boolean_type_not_nullable?
        paranoid_value == false
      else
        paranoid_value.nil?
      end
    end

    alias_method :destroyed?, :deleted?

    private

    def get_reflection_class(reflection)
      if reflection.macro == :belongs_to && reflection.options.include?(:polymorphic)
        self.send(reflection.foreign_type).constantize
      else
        reflection.klass
      end
    end

    def paranoid_value=(value)
      self.send("#{self.class.paranoid_column}=", value)
    end
  end
end
