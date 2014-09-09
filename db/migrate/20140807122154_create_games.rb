class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.text :current_state, default: '{"pieces": {}, "board": {}}'
      t.text :moves, default: ''

      t.timestamps
    end
  end
end
