# frozen_string_literal: true

class CreateLfgPosts < ActiveRecord::Migration[5.1]
  def change
    create_table :lfg_posts do |t|
      t.boolean :is_fireteam_post
      t.text :player_data
      t.string :fireteam_name
      t.string :fireteam_data, array: true, default: []

      t.timestamps
    end
  end
end
