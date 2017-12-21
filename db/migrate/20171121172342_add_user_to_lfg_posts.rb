# frozen_string_literal: true

class AddUserToLfgPosts < ActiveRecord::Migration[5.1]
  def change
    add_reference :lfg_posts, :user, foreign_key: true
    add_index :lfg_posts, %i[user_id created_at]
  end
end
