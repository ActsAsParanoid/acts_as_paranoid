# frozen_string_literal: true

require "test_helper"

class InheritanceTest < ActiveSupport::TestCase
  class SuperParanoid < ActiveRecord::Base
    acts_as_paranoid
    belongs_to :has_many_inherited_super_paranoidz
  end

  class HasManyInheritedSuperParanoidz < ActiveRecord::Base
    has_many :super_paranoidz, class_name: "InheritedParanoid", dependent: :destroy
  end

  class InheritedParanoid < SuperParanoid
    acts_as_paranoid
  end

  def setup
    ActiveRecord::Schema.define(version: 1) do
      create_table :super_paranoids do |t|
        t.string :type
        t.references :has_many_inherited_super_paranoidz,
                     index: { name: "index__sp_id_on_has_many_isp" }
        t.datetime :deleted_at

        timestamps t
      end

      create_table :has_many_inherited_super_paranoidzs do |t|
        t.references :super_paranoidz, index: { name: "index_has_many_isp_on_sp_id" }
        t.datetime :deleted_at

        timestamps t
      end
    end
  end

  def teardown
    teardown_db
  end

  def test_destroy_dependents_with_inheritance
    has_many_inherited_super_paranoidz = HasManyInheritedSuperParanoidz.new
    has_many_inherited_super_paranoidz.save
    has_many_inherited_super_paranoidz.super_paranoidz.create
    assert_nothing_raised { has_many_inherited_super_paranoidz.destroy }
  end

  def test_class_instance_variables_are_inherited
    assert_nothing_raised { InheritedParanoid.paranoid_column }
  end
end
