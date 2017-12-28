# frozen_string_literal: true

class AddItemsToItemSets < ActiveRecord::Migration[5.1]
  def change
    add_column :item_sets, :ship, :bigint
    add_column :item_sets, :shell, :bigint
    add_column :item_sets, :emblem, :bigint
    add_column :item_sets, :emote, :bigint
  end
end
