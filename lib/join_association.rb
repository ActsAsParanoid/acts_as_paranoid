module ActsAsParanoid
  module JoinAssociation
    def self.included(base)
      base.class_eval do

        alias_method :orig_build_constraint, :build_constraint
        # Add paranoid_default_scope_sql as conditions when join other table
        # <t>Blog.joins(:users)</t> would produce
        # <t>select blogs.* from blogs inner join users on users.id = blogs.user_id AND users.deleted_at is NULL</t>
        # ref https://github.com/goncalossilva/acts_as_paranoid/issues/71
        def build_constraint(reflection, table, key, foreign_table, foreign_key)
          constraint = orig_build_constraint(reflection, table, key, foreign_table, foreign_key)

          if reflection.klass.paranoid?
            constraint = constraint.and(table[reflection.klass.paranoid_column].eq(nil))
          end
          constraint
        end

      end
    end
  end
end