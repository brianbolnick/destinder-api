class Item < ApplicationRecord
  belongs_to :item_set, optional: true
end
