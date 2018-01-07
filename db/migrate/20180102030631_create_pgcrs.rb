# frozen_string_literal: true

class CreatePgcrs < ActiveRecord::Migration[5.1]
  def change
    create_table :pgcrs do |t|
      t.references :character, foreign_key: true
      t.integer :mode
      t.jsonb :data

      t.timestamps
    end
  end
end
