class AddCharacterDataToLfgPosts < ActiveRecord::Migration[5.1]
  def change
    add_column :lfg_posts, :character_data, :text
  end
end
