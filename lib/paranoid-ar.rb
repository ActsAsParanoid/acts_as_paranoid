module ActiveRecord
  module Acts #:nodoc:
    module Paranoid
      def self.included(base) # :nodoc:
        base.extend ClassMethods
      end

      # Specify this act 
      module ClassMethods
        def acts_as_paranoid
          class_eval do
            alias_method :destroy!, :destroy
            class << self
              alias_method :find_with_deleted, :find
              alias_method :count_with_deleted, :count
            end
            include ParanoidMethods
          end
        end
      end
    end
    
    module ParanoidMethods #:nodoc:
      def self.included(base) # :nodoc:
        base.extend ClassMethods
      end
      
      module ClassMethods
        def find(*args)
          if [:all, :first].include?(args.first)
            constrain = "#{table_name}.deleted_at IS NULL"
            constrains = (scope_constrains.nil? or scope_constrains[:conditions].nil? or scope_constrains[:conditions] == constrain) ?
              constrain :
              "#{scope_constrains[:conditions]} AND #{constrain}"
            constrain(:conditions => constrains) { return find_with_deleted(*args) }
          end
          find_with_deleted(*args)
        end
    
        def count(conditions = nil, joins = nil)
          constrain(:conditions => "#{table_name}.deleted_at IS NULL") { count_with_deleted(conditions, joins) }
        end
      end
      
      def destroy
        unless new_record?
          sql = self.class.send(:sanitize_sql,
            ["UPDATE #{self.class.table_name} SET deleted_at = ? WHERE id = ?", 
              self.class.default_timezone == :utc ? Time.now.utc : Time.now, id])
          self.connection.update(sql)
        end
        freeze
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include ActiveRecord::Acts::Paranoid
end

#ActiveRecord::Associations::HasAndBelongsToManyAssociation.class_eval do
#  alias_method :find_with_deleted, :find
#  def find(*args)
#    constrain(:conditions => "#{@join_table}.deleted_at IS NULL") { find_with_deleted(*args) }
#  end
#end