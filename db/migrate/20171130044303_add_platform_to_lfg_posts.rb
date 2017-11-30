class AddPlatformToLfgPosts < ActiveRecord::Migration[5.1]
  def change
    add_column :lfg_posts, :platform, :string
  end
end
