class CreateGuesses < ActiveRecord::Migration[7.0]
  def change
    create_table :guesses do |t|
      t.string :email, null: false
      t.string :answer, null: false
      t.float :latitude, null: false
      t.float :longitude, null: false
      t.references :treasure, null: false, foreign_key: true
      t.boolean :is_winner, null: false, default: false
      t.integer :winning_distance
      t.timestamps
    end
  end
end
