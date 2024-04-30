class FantasyManager < ActiveRecord::Base
  belongs_to :fantasy_team
  has_many :players, through: :fantasy_team
end

class FantasyTeam < ActiveRecord::Base
  has_many :fantasy_owners
  has_many :players
end
