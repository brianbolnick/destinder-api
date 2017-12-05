class CreateFireteams < ActiveRecord::Migration[5.1]
  def change
    create_table :fireteams do |t|

      t.timestamps
    end
  end
end
