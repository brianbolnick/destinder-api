# frozen_string_literal: true

class AddFormDataToLfgPosts < ActiveRecord::Migration[5.1]
  def change
    add_column :lfg_posts, :has_mic, :boolean
    add_column :lfg_posts, :looking_for, :string
    add_column :lfg_posts, :game_type, :text
  end
end
