class AddItemHashToItems < ActiveRecord::Migration[5.1]
  def change
    add_column :items, :item_hash, :bigint
  end
end
