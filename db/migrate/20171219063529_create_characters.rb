class CreateCharacters < ActiveRecord::Migration[5.1]
  def change
    create_table :characters do |t|
      t.string :character_id
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
