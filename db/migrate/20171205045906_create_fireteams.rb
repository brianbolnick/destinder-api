# frozen_string_literal: true

class CreateFireteams < ActiveRecord::Migration[5.1]
  def change
    create_table :fireteams, &:timestamps
  end
end
