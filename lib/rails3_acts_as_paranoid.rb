require 'active_record'
require 'validations/uniqueness_without_deleted'

class Object
  class << self
    def is_paranoid?
      false
    end
  end
end

module ActsAsParanoid
  def acts_as_paranoid(options = {})
    raise ArgumentError, "Hash expected, got #{options.class.name}" if not options.is_a?(Hash) and not options.empty?

    configuration = { :column => "deleted_at", :column_type => "time", :recover_dependent_associations => true, :dependent_recovery_window => 5.minutes }
    configuration.update(options) unless options.nil?

    type = case configuration[:column_type]
      when "time" then "Time.now"
      when "boolean" then "true"
      else
        raise ArgumentError, "'time' or 'boolean' expected for :column_type option, got #{configuration[:column_type]}"
    end

    column_reference = "#{self.table_name}.#{configuration[:column]}"

    class_eval <<-EOV
      default_scope where("#{column_reference} IS ?", nil)

      class << self
        def is_paranoid?
          true
        end

        def with_deleted
          self.unscoped.where("") #self.unscoped.reload
        end

        def only_deleted
          self.unscoped.where("#{column_reference} IS NOT ?", nil)
        end

        def delete_all!(conditions = nil)
          self.unscoped.delete_all!(conditions)
        end

        def delete_all(conditions = nil)
          update_all ["#{configuration[:column]} = ?", #{type}], conditions
        end

        def paranoid_column
          :"#{configuration[:column]}"
        end

        def paranoid_column_type
          :"#{configuration[:column_type]}"
        end

        def dependent_associations
          self.reflect_on_all_associations.select {|a| [:delete_all, :destroy].include?(a.options[:dependent]) }
        end
      end

      def paranoid_value
        self.send(self.class.paranoid_column)
      end

      def destroy!
        before_destroy() if respond_to?(:before_destroy)

        #{self.name}.delete_all!(:id => self)

        after_destroy() if respond_to?(:after_destroy)
      end

      def destroy
        run_callbacks :destroy do
          if paranoid_value == nil
            #{self.name}.delete_all(:id => self.id)
          else
            #{self.name}.delete_all!(:id => self.id)
          end
        end
      end

      def recover(options = {})
        options = {
                    :recursive => #{configuration[:recover_dependent_associations]},
                    :recovery_window => #{configuration[:dependent_recovery_window]}
                  }.merge(options)

        self.class.transaction do
          recover_dependent_associations(options[:recovery_window], options) if options[:recursive]

          self.update_attribute(self.class.paranoid_column, nil)
        end
      end

      def recover_dependent_associations(window, options)
        self.class.dependent_associations.each do |association|
          if association.collection? && self.send(association.name).is_paranoid?
            self.send(association.name).unscoped do
              self.send(association.name).deleted_around(paranoid_value, window).each do |object|
                object.recover(options) if object.respond_to?(:recover)
              end
            end
          elsif association.macro == :has_one && association.klass.is_paranoid?
            association.klass.unscoped do
              object = association.klass.deleted_around(paranoid_value, window).send('find_by_'+association.primary_key_name, self.id)
              object.recover(options) if object && object.respond_to?(:recover)
            end
          elsif association.klass.is_paranoid?
            association.klass.unscoped do
              id = self.send(association.primary_key_name)
              object = association.klass.deleted_around(paranoid_value, window).find_by_id(id)
              object.recover(options) if object && object.respond_to?(:recover)
            end
          end
        end
      end

      def deleted?
        !self.#{configuration[:column]}.nil?
      end

      scope :deleted_around, lambda {|value, window|
        if self.class.is_paranoid?
          if self.class.paranoid_column_type == 'time' && ![true, false].include?(value)
            self.where("\#{self.class.paranoid_column} > ? AND \#{self.class.paranoid_column} < ?", (value - window), (value + window))
          else
            self.only_deleted
          end
        end
      }

      ActiveRecord::Relation.class_eval do
        alias_method :delete_all!, :delete_all
        alias_method :destroy!, :destroy
      end
    EOV
  end
  
  def validates_as_paranoid
    class_eval <<-EOV
      send :extend, ParanoidValidations::ClassMethods
    EOV
  end
end

# Extend ActiveRecord's functionality
ActiveRecord::Base.send :extend, ActsAsParanoid
