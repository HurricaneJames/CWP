class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.text :current_state
      t.text :moves

      t.timestamps
    end
  end
end
