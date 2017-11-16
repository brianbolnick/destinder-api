class AddFieldsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :display_name, :string
    add_column :users, :api_membership_type, :int
    add_column :users, :api_membership_id, :int
    add_column :users, :provider, :string
    add_column :users, :about, :string
    add_column :users, :profile_picture, :string
  end
end
