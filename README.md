# ActsAsParanoid

[![Build Status](https://travis-ci.org/ActsAsParanoid/acts_as_paranoid.png?branch=master)](https://travis-ci.org/ActsAsParanoid/acts_as_paranoid)

A Rails plugin to add soft delete.

This gem can be used to hide records instead of deleting them, making them recoverable later.

## Support

**This branch targets Rails 4.x. and 5.x**

If you're working with another version, switch to the corresponding branch, or require an older version of the `acts_as_paranoid` gem.

## Usage

You can enable ActsAsParanoid like this:

```ruby
class Paranoiac < ActiveRecord::Base
  acts_as_paranoid
end
```

### Options

You can also specify the name of the column to store it's *deletion* and the type of data it holds:

- `:column      => 'deleted_at'`
- `:column_type => 'time'`

The values shown are the defaults. While *column* can be anything (as long as it exists in your database), *type* is restricted to:

- `boolean`
- `time` or
- `string`

If your column type is a `string`, you can also specify which value to use when marking an object as deleted by passing `:deleted_value` (default is "deleted"). Any records with a non-matching value in this column will be treated normally (ie: not deleted).

If your column type is a `boolean`, it is possible to specify `allow_nulls` option which is `true` by default. When set to `false`, entities that have `false` value in this column will be considered not deleted, and those which have `true` will be considered deleted. When `true` everything that has a not-null value will be considered deleted.

### Filtering

If a record is deleted by ActsAsParanoid, it won't be retrieved when accessing the database.

So, `Paranoiac.all` will **not** include the **deleted records**.

When you want to access them, you have 2 choices:

```ruby
Paranoiac.only_deleted # retrieves only the deleted records
Paranoiac.with_deleted # retrieves all records, deleted or not
```

When using the default `column_type` of `'time'`, the following extra scopes are provided:

```ruby
time = Time.now

Paranoiac.deleted_after_time(time)
Paranoiac.deleted_before_time(time)

# Or roll it all up and get a nice window:
Paranoiac.deleted_inside_time_window(time, 2.minutes)
```

### Real deletion

In order to really delete a record, just use:

```ruby
paranoiac.destroy!
Paranoiac.delete_all!(conditions)
```

You can also permanently delete a record by calling `destroy_fully!` on the object.

Alternatively you can permanently delete a record by calling `destroy` or `delete_all` on the object **twice**.

If a record was already deleted (hidden by `ActsAsParanoid`) and you delete it again, it will be removed from the database.

Take this example:

```ruby
p = Paranoiac.first
p.destroy # does NOT delete the first record, just hides it
Paranoiac.only_deleted.where(:id => p.id).destroy # deletes the first record from the database
```

### Recovery

Recovery is easy. Just invoke `recover` on it, like this:

```ruby
Paranoiac.only_deleted.where("name = ?", "not dead yet").first.recover
```

All associations marked as `:dependent => :destroy` are also recursively recovered.

If you would like to disable this behavior, you can call `recover` with the `recursive` option:

```ruby
Paranoiac.only_deleted.where("name = ?", "not dead yet").first.recover(:recursive => false)
```

If you would like to change this default behavior for one model, you can use the `recover_dependent_associations` option

```ruby
class Paranoiac < ActiveRecord::Base
    acts_as_paranoid :recover_dependent_associations => false
end
```

By default, dependent records will be recovered if they were deleted within 2 minutes of the object upon which they depend.

This restores the objects to the state before the recursive deletion without restoring other objects that were deleted earlier.

The behavior is only available when both parent and dependant are using timestamp fields to mark deletion, which is the default behavior.

This window can be changed with the `dependent_recovery_window` option:

```ruby
class Paranoiac < ActiveRecord::Base
    acts_as_paranoid
    has_many :paranoids, :dependent => :destroy
end

class Paranoid < ActiveRecord::Base
    belongs_to :paranoic

    # Paranoid objects will be recovered alongside Paranoic objects
    # if they were deleted within 10 minutes of the Paranoic object
    acts_as_paranoid :dependent_recovery_window => 10.minutes
end
```

or in the recover statement

```ruby
Paranoiac.only_deleted.where("name = ?", "not dead yet").first.recover(:recovery_window => 30.seconds)
```

### Validation
ActiveRecord's built-in uniqueness validation does not account for records deleted by ActsAsParanoid. If you want to check for uniqueness among non-deleted records only, use the macro `validates_as_paranoid` in your model. Then, instead of using `validates_uniqueness_of`, use `validates_uniqueness_of_without_deleted`. This will keep deleted records from counting against the uniqueness check.

```ruby
class Paranoiac < ActiveRecord::Base
  acts_as_paranoid
  validates_as_paranoid
  validates_uniqueness_of_without_deleted :name
end

p1 = Paranoiac.create(:name => 'foo')
p1.destroy

p2 = Paranoiac.new(:name => 'foo')
p2.valid? #=> true
p2.save

p1.recover #=> fails validation!
```

### Status
You can check the status of your paranoid objects with the `deleted?` helper

```ruby
Paranoiac.create(:name => 'foo').destroy
Paranoiac.with_deleted.first.deleted? #=> true
```

### Scopes

As you've probably guessed, `with_deleted` and `only_deleted` are scopes. You can, however, chain them freely with other scopes you might have.

For example:

```ruby
Paranoiac.pretty.with_deleted
```

This is exactly the same as:

```ruby
Paranoiac.with_deleted.pretty
```

You can work freely with scopes and it will just work:

```ruby
class Paranoiac < ActiveRecord::Base
  acts_as_paranoid
  scope :pretty, where(:pretty => true)
end

Paranoiac.create(:pretty => true)

Paranoiac.pretty.count #=> 1
Paranoiac.only_deleted.count #=> 0
Paranoiac.pretty.only_deleted.count #=> 0

Paranoiac.first.destroy

Paranoiac.pretty.count #=> 0
Paranoiac.only_deleted.count #=> 1
Paranoiac.pretty.only_deleted.count #=> 1
```

### Associations

Associations are also supported.

From the simplest behaviors you'd expect to more nifty things like the ones mentioned previously or the usage of the `:with_deleted` option with `belongs_to`

```ruby
class Parent < ActiveRecord::Base
  has_many :children, :class_name => "ParanoiacChild"
end

class ParanoiacChild < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :parent

  # You may need to provide a foreign_key like this
  belongs_to :parent_including_deleted, :class_name => "Parent", :foreign_key => 'parent_id', :with_deleted => true
end

parent = Parent.first
child = parent.children.create
parent.destroy

child.parent #=> nil
child.parent_including_deleted #=> Parent (it works!)
```

## Caveats

Watch out for these caveats:


-   You cannot use scopes named `with_deleted` and `only_deleted`
-   You cannot use scopes named `deleted_inside_time_window`, `deleted_before_time`, `deleted_after_time` **if** your paranoid column's type is `time`
-   You cannot name association `*_with_deleted`
-   `unscoped` will return all records, deleted or not

# Acknowledgements

* To [Rick Olson](https://github.com/technoweenie) for creating acts_as_paranoid
* To [cheerfulstoic](https://github.com/cheerfulstoic) for adding recursive recovery
* To [Jonathan Vaught](https://github.com/gravelpup) for adding paranoid validations
* To [Geoffrey Hichborn](https://github.com/phene) for improving the overral code quality and adding support for after_commit
* To [flah00](https://github.com/flah00) for adding support for STI-based associations (with :dependent)
* To [vikramdhillon](https://github.com/vikramdhillon) for the idea and initial implementation of support for string column type
* To [Craig Walker](https://github.com/softcraft-development) for Rails 3.1 support and fixing various pending issues
* To [Charles G.](https://github.com/chuckg) for Rails 3.2 support and for making a desperately needed global code refactoring
* To [Gonçalo Silva](https://github.com/goncalossilva) for supporting this gem prior to v0.4.3
* To [Jean Boussier](https://github.com/byroot) for initial Rails 4.0.0 support
* To [Matijs van Zuijlen](https://github.com/mvz) for Rails 4.1 and 4.2 support
* To [Andrey Ponomarenko](https://github.com/sjke) for Rails 5 support

See `LICENSE`.
