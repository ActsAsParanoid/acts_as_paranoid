module ActiveRecord #:nodoc:
  module Acts #:nodoc:
    # Overrides some basic methods for the current model so that calling #destroy sets a 'deleted_at' field to the current timestamp.
    # This assumes the table has a deleted_at date/time field.  Most normal model operations will work, but there will be some oddities.
    #
    #   class Widget < ActiveRecord::Base
    #     acts_as_paranoid
    #   end
    #
    #   Widget.find(:all)
    #   # SELECT * FROM widgets WHERE widgets.deleted_at IS NULL
    #
    #   Widget.find(:first, :conditions => ['title = ?', 'test'], :order => 'title')
    #   # SELECT * FROM widgets WHERE widgets.deleted_at IS NULL AND title = 'test' ORDER BY title LIMIT 1
    #
    #   Widget.find_with_deleted(:all)
    #   # SELECT * FROM widgets
    #
    #   Widget.find(:all, :with_deleted => true)
    #   # SELECT * FROM widgets
    #
    #   Widget.count
    #   # SELECT COUNT(*) FROM widgets WHERE widgets.deleted_at IS NULL
    #
    #   Widget.count ['title = ?', 'test']
    #   # SELECT COUNT(*) FROM widgets WHERE widgets.deleted_at IS NULL AND title = 'test'
    #
    #   Widget.count_with_deleted
    #   # SELECT COUNT(*) FROM widgets
    #
    #   @widget.destroy
    #   # UPDATE widgets SET deleted_at = '2005-09-17 17:46:36' WHERE id = 1
    #
    #   @widget.destroy!
    #   # DELETE FROM widgets WHERE id = 1
    module Paranoid
      def self.included(base) # :nodoc:
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_paranoid
          class_eval do
            alias_method :destroy_without_callbacks!, :destroy_without_callbacks
            class << self
              alias_method :original_find, :find
              alias_method :count_with_deleted, :count
            end
            include ParanoidMethods
          end
        end
      end
    
      module ParanoidMethods #:nodoc:
        def self.included(base) # :nodoc:
          base.extend ClassMethods
        end
      
        module ClassMethods
          def find(*args)
            options = extract_options_from_args!(args)
            call_original_find = lambda { original_find(*(args << options)) }
            
            if !options[:with_deleted]
              constrain = "#{table_name}.deleted_at IS NULL"
              constrains = (scope_constrains.nil? or scope_constrains[:conditions].nil? or scope_constrains[:conditions] == constrain) ?
                constrain :
                "#{scope_constrains[:conditions]} AND #{constrain}"
              constrain(:conditions => constrains) { return call_original_find.call }
            end
            
            call_original_find.call
          end

          def find_with_deleted(*args)
            original_find(*(args << extract_options_from_args!(args).merge(:with_deleted => true)))
          end

          def count(conditions = nil, joins = nil)
            constrain(:conditions => "#{table_name}.deleted_at IS NULL") { count_with_deleted(conditions, joins) }
          end
        end

        def destroy_without_callbacks
          unless new_record?
            sql = self.class.send(:sanitize_sql,
              ["UPDATE #{self.class.table_name} SET deleted_at = ? WHERE id = ?", 
                self.class.default_timezone == :utc ? Time.now.utc : Time.now, id])
            self.connection.update(sql)
          end
          freeze
        end
        
        def destroy_with_callbacks!
          return false if callback(:before_destroy) == false
          result = destroy_without_callbacks!
          callback(:after_destroy)
          result
        end
        
        def destroy!
          transaction { destroy_with_callbacks! }
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include ActiveRecord::Acts::Paranoid
end