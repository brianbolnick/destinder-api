class AddBucketHashToItems < ActiveRecord::Migration[5.1]
  def change
    add_column :items, :bucket_hash, :bigint
  end
end
