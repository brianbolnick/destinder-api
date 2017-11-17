class AddMessageToLfgPosts < ActiveRecord::Migration[5.1]
  def change
    add_column :lfg_posts, :message, :string
  end
end
