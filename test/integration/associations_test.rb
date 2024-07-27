# frozen_string_literal: true

require "test_helper"
require "minitest/spec"
require "minitest/stub_const"

class AssociationsTest < ActiveSupport::TestCase
  describe "a many-to-many association specified with has_many through:" do
    before do
      ActiveSupport::Dependencies::Reference.clear! if ActiveRecord::VERSION::MAJOR == 6
      ActiveRecord::Schema.define(version: 1) do
        create_table :authors do |t|
          t.datetime :deleted_at
          timestamps t
        end

        create_table :books do |t|
          t.datetime :deleted_at
          t.timestamps
        end

        create_table :authorships do |t|
          t.integer :author_id
          t.integer :book_id
          t.datetime :deleted_at
          t.timestamps
        end
      end
    end

    after do
      ActiveRecord::Base.connection.data_sources.each do |table|
        ActiveRecord::Base.connection.drop_table(table)
      end
    end

    describe "when relation to join table is marked as dependent: destroy" do
      let(:author_class) do
        Class.new(ActiveRecord::Base) do
          has_many :authorships, dependent: :destroy
          has_many :books, through: :authorships
        end
      end

      let(:authorship_class) do
        Class.new(ActiveRecord::Base) do
          belongs_to :author
          belongs_to :book
        end
      end

      let(:book_class) do
        Class.new(ActiveRecord::Base) do
          has_many :authorships, dependent: :destroy
          has_many :authors, through: :authorships
        end
      end

      let(:const_map) do
        {
          Author: author_class,
          Authorship: authorship_class,
          Book: book_class
        }
      end

      describe "when classes are not paranoid" do
        it "destroys the join record when calling destroy on the associated record" do
          AssociationsTest.stub_consts(const_map) do
            author = Author.create!
            book = author.books.create!
            book.destroy

            author.reload

            _(author.books).must_equal []
            _(author.authorships).must_equal []
          end
        end

        it "destroys just the join record when calling destroy on the association" do
          AssociationsTest.stub_consts(const_map) do
            author = Author.create!
            book = author.books.create!
            author.books.destroy(book)

            author.reload

            _(author.books).must_equal []
            _(author.authorships).must_equal []
            _(Book.all).must_equal [book]
          end
        end
      end
    end
  end
end
