class RemoveMeritFieldsFromUsers < ActiveRecord::Migration[5.1]
  def self.up
    remove_column :users, :sash_id
    remove_column :users, :level
  end
end
