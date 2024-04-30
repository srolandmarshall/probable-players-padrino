class CreatePlayers < ActiveRecord::Migration[6.0]
  def change
    create_table :players do |t|
      t.string :type
      t.string :full_name
      t.string :team
      t.integer :yahoo_id
      t.jsonb :data, default: {}
      t.string :first_name
      t.string :last_name
      t.jsonb :owner, default: {}
      t.string :positions, array: true, default: []

      t.timestamps
    end
  end
end
