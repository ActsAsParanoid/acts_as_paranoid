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
        without_paranoid_default_scope.where("#{paranoid_column_reference} IS NOT ?", nil)
      end

      def delete_all!(conditions = nil)
        without_paranoid_default_scope.delete_all!(conditions)
      end

      def delete_all(conditions = nil)
        update_all ["#{paranoid_configuration[:column]} = ?", delete_now_value], conditions
      end

      def paranoid_default_scope_sql
        self.scoped.table[paranoid_column].eq(nil).to_sql
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
        scope = self.scoped.with_default_scope
        scope.where_values.delete(paranoid_default_scope_sql)

        scope
      end
    end

    def paranoid_value
      self.send(self.class.paranoid_column)
    end

    def destroy!
      with_transaction_returning_status do
        run_callbacks :destroy do
          act_on_dependent_destroy_associations
          self.class.delete_all!(self.class.primary_key.to_sym => self.id)
          self.paranoid_value = self.class.delete_now_value
          freeze
        end
      end
    end

    def destroy
      if paranoid_value.nil?
        with_transaction_returning_status do
          run_callbacks :destroy do
            self.class.delete_all(self.class.primary_key.to_sym => self.id)
            self.paranoid_value = self.class.delete_now_value
            self
          end
        end
      else
        destroy!
      end
    end

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
      self.class.dependent_associations.each do |association|
        if association.collection? && self.send(association.name).paranoid?
          self.send(association.name).unscoped do
            self.send(association.name).paranoid_deleted_around_time(paranoid_value, window).each do |object|
              object.recover(options) if object.respond_to?(:recover)
            end
          end
        elsif association.macro == :has_one && association.klass.paranoid?
          association.klass.unscoped do
            object = association.klass.paranoid_deleted_around_time(paranoid_value, window).send('find_by_'+association.foreign_key, self.id)
            object.recover(options) if object && object.respond_to?(:recover)
          end
        elsif association.klass.paranoid?
          association.klass.unscoped do
            id = self.send(association.foreign_key)
            object = association.klass.paranoid_deleted_around_time(paranoid_value, window).find_by_id(id)
            object.recover(options) if object && object.respond_to?(:recover)
          end
        end
      end
    end

    def act_on_dependent_destroy_associations
      self.class.dependent_associations.each do |association|
        if association.collection? && self.send(association.name).paranoid?
          association.klass.with_deleted.instance_eval("find_all_by_#{association.foreign_key}(#{self.id.to_json})").each do |object|
            object.destroy!
          end
        end
      end
    end

    def deleted?
      !paranoid_value.nil?
    end
    alias_method :destroyed?, :deleted?

    private

    def paranoid_value=(value)
      self.send("#{self.class.paranoid_column}=", value)
    end
  end
end
