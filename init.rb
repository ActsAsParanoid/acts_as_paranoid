require 'rails3_acts_as_paranoid'
require 'validations/uniqueness_without_deleted'

ActiveRecord::Base.send :extend, ParanoidValidations::ClassMethods