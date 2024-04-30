require 'active_support/all'

# Represents a player for a fantasy sports team.
class Player < ActiveRecord::Base
  validate :positions_are_valid
  belongs_to :fantasy_team, optional: true

  def positions_are_valid
    return unless positions.empty? || (positions - self.class::VALID_POSITIONS).any?

    invalid_positions = positions - self.class::VALID_POSITIONS
    errors.add(:positions,
               "can only be #{self.class::VALID_POSITIONS.join(', ')}, invalid position(s): #{invalid_positions}")
  end

  def initialize(opts = {})
    super
    opts.each do |k, v|
      # make the instance variable name ruby-happy
      var_name = k.to_s.underscore
      # remove characters that ruby dislikes
      var_name.gsub!(/[^a-z_]/, '')
      instance_variable_set("@#{var_name}", v)
    end
  end

  def fantasy_team
    @fantasy_team ||= FantasyTeam.find_by_id(fantasy_team_id)
  end

  def fantasy_team=(team)
    @fantasy_team = team
    self.fantasy_team_id = @fantasy_team&.id
    save!
  end
end

class Pitcher < Player
  VALID_POSITIONS = %w[SP P RP].freeze
end

class Batter < Player
  VALID_POSITIONS = %w[1B 2B 3B SS C OF LF RF CF Util].freeze
end
