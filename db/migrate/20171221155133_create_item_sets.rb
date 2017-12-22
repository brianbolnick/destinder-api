# frozen_string_literal: true

class CreateItemSets < ActiveRecord::Migration[5.1]
  def change
    create_table :item_sets do |t|
      t.references :character, foreign_key: true
      t.bigint :kinetic_weapon
      t.bigint :energy_weapon
      t.bigint :power_weapon
      t.bigint :helmet
      t.bigint :gauntlets
      t.bigint :chest_armor
      t.bigint :leg_armor
      t.bigint :class_item
      t.bigint :subclass
      t.bigint :aura

      t.timestamps
    end
  end
end
