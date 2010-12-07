require 'rails3_acts_as_paranoid'
require 'uniqueness_without_deleted'

ActiveRecord::Base.send :extend, ParanoidValidations::ClassMethods