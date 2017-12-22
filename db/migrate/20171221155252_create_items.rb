# frozen_string_literal: true

class CreateItems < ActiveRecord::Migration[5.1]
  def change
    create_table :items do |t|
      t.references :item_set, foreign_key: true
      t.string :item_name
      t.string :item_type
      t.string :item_icon
      t.string :item_tier

      t.timestamps
    end
  end
end
