require 'active_record'
require 'validations/uniqueness_without_deleted'

module ActsAsParanoid
  
  def paranoid?
    self.included_modules.include?(InstanceMethods)
  end
  
  def validates_as_paranoid
    extend ParanoidValidations::ClassMethods
  end
  
  def acts_as_paranoid(options = {})
    raise ArgumentError, "Hash expected, got #{options.class.name}" if not options.is_a?(Hash) and not options.empty?
    
    class_attribute :paranoid_configuration, :paranoid_column_reference
    
    self.paranoid_configuration = { :column => "deleted_at", :column_type => "time", :recover_dependent_associations => true, :dependent_recovery_window => 2.minutes }
    self.paranoid_configuration.merge!({ :deleted_value => "deleted" }) if options[:column_type] == "string"
    self.paranoid_configuration.merge!(options) # user options

    raise ArgumentError, "'time', 'boolean' or 'string' expected for :column_type option, got #{paranoid_configuration[:column_type]}" unless ['time', 'boolean', 'string'].include? paranoid_configuration[:column_type]

    self.paranoid_column_reference = "#{self.table_name}.#{paranoid_configuration[:column]}"
    
    return if paranoid?

    ActiveRecord::Relation.class_eval do
      alias_method :delete_all!, :delete_all
      alias_method :destroy!, :destroy
    end

    # Magic!
    default_scope where("#{paranoid_column_reference} IS ?", nil)
    
    scope :paranoid_deleted_around_time, lambda {|value, window|
      if self.class.respond_to?(:paranoid?) && self.class.paranoid?
        if self.class.paranoid_column_type == 'time' && ![true, false].include?(value)
          self.where("#{self.class.paranoid_column} > ? AND #{self.class.paranoid_column} < ?", (value - window), (value + window))
        else
          self.only_deleted
        end
      end if paranoid_configuration[:column_type] == 'time'
    }
    
    include InstanceMethods
    extend ClassMethods
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
      self.unscoped
    end

    def only_deleted
      self.unscoped.where("#{paranoid_column_reference} IS NOT ?", nil)
    end

    def delete_all!(conditions = nil)
      self.unscoped.delete_all!(conditions)
    end

    def delete_all(conditions = nil)
      update_all ["#{paranoid_configuration[:column]} = ?", delete_now_value], conditions
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
  end
  
  module InstanceMethods
    
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

# Extend ActiveRecord's functionality
ActiveRecord::Base.send :extend, ActsAsParanoid

# Push the recover callback onto the activerecord callback list
ActiveRecord::Callbacks::CALLBACKS.push(:before_recover, :after_recover)
