class AddCheckpointToLfgPosts < ActiveRecord::Migration[5.1]
  def change
    add_column :lfg_posts, :checkpoint, :string
  end
end
