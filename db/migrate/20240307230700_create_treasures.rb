class CreateTreasures < ActiveRecord::Migration[7.0]
  def change
    create_table :treasures do |t|
      t.string :answer, null: false
      t.float :latitude, null: false
      t.float :longitude, null: false
      t.boolean :active, null: false, default: false
      t.timestamps
    end
  end
end
