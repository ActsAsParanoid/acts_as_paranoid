# frozen_string_literal: true

require "test_helper"
require "minitest/spec"
require "minitest/stub_const"
require "minitest/around"

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

    around do |test|
      AssociationsTest.stub_consts(const_map) do
        test.call
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

      let(:author) { Author.first }
      let(:book) { Book.first }

      before do
        author = Author.create!
        author.books.create!
      end

      describe "when classes are not paranoid" do
        it "destroys the join record when calling destroy on the associated record" do
          book.destroy

          _(author.reload.books).must_equal []
          _(author.authorships).must_equal []
        end

        it "destroys just the join record when calling destroy on the association" do
          author.books.destroy(book)

          _(author.reload.books).must_equal []
          _(author.authorships).must_equal []
          _(Book.all).must_equal [book]
        end
      end

      describe "when classes are paranoid" do
        before do
          # NOTE: Because Book.authorships is dependent: destroy, if Book is
          # paranoid, Authorship should also be paranoid.
          authorship_class.acts_as_paranoid
          book_class.acts_as_paranoid
        end

        it "destroys the join record when calling destroy on the associated record" do
          book.destroy

          _(author.reload.books).must_equal []
          _(author.authorships).must_equal []
        end

        it "destroys just the join record when calling destroy on the association" do
          author.books.destroy(book)

          _(author.reload.books).must_equal []
          _(author.authorships).must_equal []
          _(Book.all).must_equal [book]
        end

        it "includes destroyed records with deleted join records in .with_deleted scope" do
          book.destroy

          _(author.reload.books.with_deleted).must_equal [book]
        end

        it "includes records with deleted join records in .with_deleted scope" do
          author.books.destroy(book)

          _(author.reload.books.with_deleted).must_equal [book]
        end
      end
    end

    describe "when relation to join table is not marked as dependent" do
      let(:author_class) do
        Class.new(ActiveRecord::Base) do
          has_many :authorships
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
          has_many :authorships
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

      let(:author) { Author.first }
      let(:book) { Book.first }

      before do
        author = Author.create!
        author.books.create!
      end

      describe "when classes are not paranoid" do
        it "destroys just the associated record when calling destroy on it" do
          book.destroy

          _(author.reload.books).must_equal []
          _(author.authorships).wont_equal []
        end

        it "destroys just the join record when calling destroy on the association" do
          author.books.destroy(book)

          _(author.reload.books).must_equal []
          _(author.authorships).must_equal []
          _(Book.all).must_equal [book]
        end
      end

      describe "when classes are paranoid" do
        before do
          # NOTE: Because Book.authorships is dependent: destroy, if Book is
          # paranoid, Authorship should also be paranoid.
          authorship_class.acts_as_paranoid
          book_class.acts_as_paranoid
        end

        it "destroys the join record when calling destroy on the associated record" do
          book.destroy

          _(author.reload.books).must_equal []
          _(author.authorships).wont_equal []
        end

        it "destroys just the join record when calling destroy on the association" do
          author.books.destroy(book)

          _(author.reload.books).must_equal []
          _(author.authorships).must_equal []
          _(Book.all).must_equal [book]
        end

        it "includes destroyed associated records in .with_deleted scope" do
          book.destroy

          _(author.reload.books.with_deleted).must_equal [book]
        end

        it "includes records with deleted join records in .with_deleted scope" do
          author.books.destroy(book)

          _(author.reload.books.with_deleted).must_equal [book]
        end
      end
    end
  end
end
