# frozen_string_literal: true

class AddMoreItemsToItemSets < ActiveRecord::Migration[5.1]
  def change
    add_column :item_sets, :clan_banners, :bigint
    add_column :item_sets, :vehicle, :bigint
  end
end
