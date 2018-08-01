# frozen_string_literal: true

require "test_helper"

# load ActiveStorage
require "global_id"
ActiveRecord::Base.include(GlobalID::Identification)
GlobalID.app = "ActsAsParanoid"

require "active_job"
ActiveJob::Base.queue_adapter = :test
ActiveJob::Base.logger = Logger.new(File::NULL)

require "active_support/cache"

require "active_storage"
require "active_storage/attached"
require "active_storage/service/disk_service"
require "active_storage/reflection"
ActiveRecord::Base.include(ActiveStorage::Reflection::ActiveRecordExtensions)
ActiveRecord::Reflection.singleton_class.prepend(ActiveStorage::Reflection::ReflectionExtension)
ActiveRecord::Base.include(ActiveStorage::Attached::Model)

require "#{Gem.loaded_specs['activestorage'].full_gem_path}/app/models/active_storage/record"
module ActiveStorage
  class Blob < Record
  end
end
Dir.glob("#{Gem.loaded_specs['activestorage'].full_gem_path}/app/models/active_storage/blob/*").sort.each do |f|
  require f
end
$LOAD_PATH << "#{Gem.loaded_specs['activestorage'].full_gem_path}/app/models/"
Dir.glob("#{Gem.loaded_specs['activestorage'].full_gem_path}/app/models/active_storage/*").sort.each do |f|
  require f
end
if ActiveStorage::Blob.respond_to?(:services=)
  require "active_storage/service/disk_service"
  ActiveStorage::Blob.services = {
    "test" => ActiveStorage::Service::DiskService.build(name: "test", configurator: nil, root: "test/tmp")
  }
end
if File.exist?("#{Gem.loaded_specs['activestorage'].full_gem_path}/app/jobs/active_storage/base_job.rb")
  require "#{Gem.loaded_specs['activestorage'].full_gem_path}/app/jobs/active_storage/base_job"
end
Dir.glob("#{Gem.loaded_specs['activestorage'].full_gem_path}/app/jobs/active_storage/*").sort.each do |f|
  require f
end
ActiveStorage::Blob.service = ActiveStorage::Service::DiskService.new(root: "test/tmp")

class ParanoidActiveStorageTest < ActiveSupport::TestCase
  self.file_fixture_path = "test/fixtures"

  class ParanoidActiveStorage < ActiveRecord::Base
    acts_as_paranoid

    has_one_attached :main_file
    has_many_attached :files
    has_one_attached :undependent_main_file, dependent: false
    has_many_attached :undependent_files, dependent: false
  end

  def setup_db
    ActiveRecord::Schema.define(version: 1) do
      create_table :active_storage_blobs do |t|
        t.string :key, null: false
        t.string :filename, null: false
        t.string :content_type
        t.text :metadata
        t.string :service_name
        t.bigint :byte_size, null: false
        t.string :checksum, null: false
        t.datetime :created_at, null: false
        t.index [:key], name: "index_active_storage_blobs_on_key", unique: true
      end

      create_table :active_storage_attachments do |t|
        t.string :name, null: false
        t.references :record, null: false, polymorphic: true, index: false
        t.references :blob, null: false
        t.datetime :created_at, null: false
        t.index [:record_type, :record_id, :name, :blob_id], name: "index_active_storage_attachments_uniqueness", unique: true
      end

      create_table :active_storage_variant_records do |t|
        t.belongs_to :blob, null: false, index: false
        t.string :variation_digest, null: false
        t.index [:blob_id, :variation_digest], name: "index_active_storage_variant_records_uniqueness", unique: true
      end

      create_table :paranoid_active_storages do |t|
        t.datetime :deleted_at
        timestamps t
      end
    end
  end

  def clean_active_storage_attachments
    Dir.glob("test/tmp/*").each do |f|
      FileUtils.rm_r(f)
    end
  end

  def create_file_blob(filename: "hello.txt", content_type: "text/plain", metadata: nil)
    args = { io: file_fixture(filename).open, filename: filename, content_type: content_type, metadata: metadata, service_name: "test" }
    if ActiveStorage::Blob.respond_to?(:create_and_upload!)
      ActiveStorage::Blob.create_and_upload!(**args)
    else
      ActiveStorage::Blob.create_after_upload!(**args)
    end
  end

  def setup
    setup_db
  end

  def teardown
    super
    clean_active_storage_attachments
  end

  def test_paranoid_active_storage
    pt = ParanoidActiveStorage.create({
      main_file: create_file_blob,
      files: [create_file_blob, create_file_blob],
      undependent_main_file: create_file_blob,
      undependent_files: [create_file_blob, create_file_blob]
    })
    pt.destroy
  end
end
