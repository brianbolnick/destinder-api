class CreateCharacterDetails < ActiveRecord::Migration[5.1]
  def change
    create_table :character_details do |t|
      t.references :character, foreign_key: true
      t.string :character_type
      t.string :subclass
      t.integer :light_level
      t.string :emblem
      t.string :emblem_background
      t.string :last_login

      t.timestamps
    end
  end
end
