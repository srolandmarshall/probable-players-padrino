class CreateFantasyTables < ActiveRecord::Migration[7.1]
  def change
    create_table :fantasy_managers do |t|
      t.belongs_to :fantasy_team
      t.integer :manager_id
      t.string :nickname
      t.string :img_url
    end

    create_table :fantasy_teams do |t|
      t.string :team_key
      t.string :team_name
      t.string :team_logo_url
      t.integer :waiver_priority
      t.integer :weekly_moves
      t.references :fantasy_manager
      t.timestamps
    end

    add_column :players, :fantasy_team_id, :integer
    remove_column :players, :owner, :jsonb
  end
end
