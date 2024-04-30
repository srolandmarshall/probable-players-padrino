require 'bundler/setup'
require 'padrino-core/cli/rake'

PadrinoTasks.use(:database)
PadrinoTasks.use(:activerecord)
PadrinoTasks.init

# namespace :data do
#   desc 'seed the yahoo players table'
#   task :seed_players do
#     csv_path = File.join(File.dirname(__FILE__), 'data/yahoo_ids.csv')
#     players = CSV.foreach(csv_path, headers: true)

#     ActiveRecord::Base.transaction do
#       players.each do |row|
#         create_player_with_type(build_player_data(row))
#       rescue StandardError => e
#         puts "Error seeding player: #{e.message}"
#         binding.pry
#       end
#     end

#     puts "#{Player.count} players seeded."
#   end

#   task :clear_teams_and_owners do
#     FantasyManager.destroy_all
#     FantasyTeam.destroy_all
#   end

#   task :seed_teams_and_owners do
#     yahoo = YahooAPI.new
#     league_id = 88_700
#     teams = yahoo.get_teams_from_league(league_id)
#     teams.each do |team_data|
#       team = create_fantasy_team(team_data)
#       managers = team_data['managers']['manager']
#       if managers.is_a?(Array)
#         # create multiple Managers for the team
#         managers.each do |manager|
#           create_fantasy_manager(manager, team)
#         end
#       elsif managers.is_a?(Hash)
#         # create single Manager for the team
#         create_fantasy_manager(managers, team)
#       end
#     end
#   end

#   def build_player_data(row)
#     {
#       full_name: row['Full Name'],
#       yahoo_id: row['id'],
#       team: row['Team'],
#       first_name: row['First Name'],
#       last_name: row['Last Name'],
#       positions: row['Position'].split(',')
#     }
#   end

#   def create_player_with_type(data)
#     positions = Array(data[:positions]).flatten
#     player = if positions.any? { |pos| Pitcher::VALID_POSITIONS.include?(pos) }
#                Pitcher.create(data)
#              else
#                Batter.create(data)
#              end
#     puts "Created #{player.class}: #{player.full_name} (#{positions.join(', ')}" if player&.errors&.empty?
#   end

#   def create_fantasy_manager(manager, team = nil)
#     puts "Creating manager: #{manager['nickname']} (#{manager['manager_id']})"
#     puts "Associated with team: #{team.team_name}" if team.persisted?
#     FantasyManager.create!(
#       manager_id: manager['manager_id'],
#       nickname: manager['nickname'],
#       img_url: manager['image_url'],
#       fantasy_team: team
#     )
#   end

#   def create_fantasy_team(team)
#     puts "Creating team: #{team['name']}"
#     FantasyTeam.create!(
#       team_key: team['team_key'],
#       team_name: team['name'],
#       team_logo_url: team['team_logos']['team_logo']['url'],
#       waiver_priority: team['waiver_priority'],
#       weekly_moves: team['roster_adds']['value'].to_i
#     )
#   end

#   task :dump_rosters do
#     yahoo = YahooAPI.new
#     league_id = 88_700
#     roster_data = yahoo.get_roster_data({ league_id: league_id })
#     File.open("data/rosters_dump_#{Date.current}.json", 'w') { |f| f.write(roster_data.to_json) }
#   end

#   task :reset_ownership_from_file do
#     puts 'Resetting player ownership data...'
#     Player.update_all(fantasy_team_id: nil)
#     puts 'Player ownership data nullified, processing latest roster dump...'
#     # get latest roster data from data/rosters_dump_*.json
#     file = Dir['data/rosters_dump_*.json'].sort.last
#     roster_data = JSON.parse(File.read(file))
#     roster_data.each do |roster_hash|
#       roster = roster_hash['roster']
#       team = FantasyTeam.find_by_team_key(roster_hash['team_key'])
#       roster.each do |player_data|
#         yahoo_id = player_data['player_id']
#         begin
#           player = Player.find_by_yahoo_id(yahoo_id.to_i)
#           if player
#             player.fantasy_team = team
#             player.save!
#             puts "Updated player ownership for #{player.full_name} to #{team.team_name}" if player.team
#           else
#             player_hash = {
#               yahoo_id: yahoo_id,
#               fantasy_team: team,
#               full_name: player_data['name']['full'],
#               team: player_data['editorial_team_abbr'],
#               first_name: player_data['name']['first'],
#               last_name: player_data['name']['last'],
#               positions: player_data['eligible_positions']['position']
#             }
#             create_player_with_type(player_hash)
#           end
#         rescue StandardError => e
#           puts "Error updating player ownership: #{e.message}"
#         end
#       end
#     end
#   end
# end
