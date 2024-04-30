require 'dotenv/load'
require 'oauth2'
require 'pry'
require 'active_support/all'
require 'ostruct'

class YahooToken
  attr_reader :client
  attr_writer :access_token
  attr_accessor :token_path

  def initialize(token_path, client)
    @token_path = token_path
    @access_token = nil
    @client = client
  end

  def access_token
    refresh_token! if @access_token&.expired?
    @access_token ||= begin
      if file_is_valid
        check_token_expiry
      else
        authenticate
      end
    rescue StandardError => e
      handle_token_error(e)
    end
  end

  def authenticate
    auth_url = @client.auth_code.authorize_url(redirect_uri: 'oob',
                                               response_type: 'code',)
    puts "Please visit the following URL to authorize your application:
 #{auth_url}"
    puts 'Enter the authorization code: '
    auth_code = $stdin.gets.chomp

    @access_token = @client.auth_code.get_token(auth_code, redirect_uri: 'oob').tap do |token|
      write_access_token(token)
    end
  end

  def refresh_token!
    @access_token = access_token.tap do |token|
      puts 'Refreshing access_token.'
      token.refresh!
    rescue StandardError => e
      puts "Error refreshing access token: #{e}"
      authenticate
    ensure
      write_access_token(token)
    end
  end

  def write_access_token(token)
    puts "Writing access token to #{@token_path}"
    JSON.dump(token.response.parsed, File.open(@token_path, 'w'))
  end

  def token_from_file
    OAuth2::AccessToken.from_hash(@client, read_access_token_file)
  end

  private

  def file_is_valid
    return false unless File.exist?(@token_path)
    return false if File.size(@token_path).zero?

    true
  end

  def read_access_token_file
    JSON.parse(File.read(@token_path))
  end

  def check_token_expiry
    token = token_from_file
    token = refresh_token! if token.expired?
    token
  end

  def handle_token_error(error)
    puts "Error reading access token: #{error} Re-authenticating."
    authenticate
  end
end

class YahooAPI
  attr_reader :client, :token_manager

  def initialize(client_id = ENV['YAHOO_CLIENT_ID'], client_secret = ENV['YAHOO_CLIENT_SECRET'])
    @client = OAuth2::Client.new(client_id, client_secret, site: 'https://api.login.yahoo.com/',
                                                           authorize_url: 'oauth2/request_auth',
                                                           token_url: 'oauth2/get_token',)
    @token_manager = YahooToken.new('./data/yahoo_access_token.json', @client)
  end

  def get(uri)
    @token_manager.access_token.get(uri).parsed.deep_symbolize_keys
  rescue OAuth2::Error => e
    puts "Something broke, going to reauthenticate: #{e}"
    binding.pry
    authenticate
  end

  def handle_token_error(error)
    puts "Error reading access token: #{error} Re-authenticating."
    authenticate
  end

  def uris(opts = {})
    base = 'https://fantasysports.yahooapis.com/fantasy/v2'
    # opath = ownership_path(opts[:player_ids], opts[:league])
    opath = ownership_path(test_values[:player_ids], test_values[:league_key])

    { base: base,
      league: "#{base}/league/",
      team: "#{base}/team/",
      user: "#{base}/users;use_login=1/",
      ownership: "#{base}/#{opath}" }
  end

  def build_uri(type, opts = {})
    uri = uris[type]&.tap do |base|
      base << "#{opts[:path]}/" if opts[:path].present?
      base << "?#{opts[:query_params].to_query}" if opts[:query_params].present?
    end
    "#{uri}?format=json"
  end

  def ownership_path(player_ids, league)
    base = 'https://fantasysports.yahooapis.com/fantasy/v2/'
    base + "league/#{league}/players;player_keys=#{player_keys(player_ids)}/ownership"
  end

  def parse_hash_ownership_data(league_data)
    players = league_data['players']['player']
    players.map do |player|
      yahoo_id = player['player_id']
      player_name = player['name']['full']
      ownership_data = player['ownership']
      { full_name: player_name, yahoo_id: yahoo_id, owner: owner_data(ownership_data) }
    end.compact
  end

  def parse_array_ownership_data(league_data)
    players = league_data.second['players']['player']
    players.map do |key, player_parent|
      next if key == 'count'

      player_data = player_parent['player'].first
      yahoo_id = player_data.find { |hash| hash.key?('player_id') }['player_id']
      player_name = player_data.find { |hash| hash.key?('name') }['name']['full']
      ownership_data = player_parent['player'].second['ownership']
      { full_name: player_name, yahoo_id: yahoo_id, owner: owner_data(ownership_data) }
    end.compact
  end

  def ownership_data_output(ownership_data)
    owner = owner_data(ownership_data)
    { full_name: player_name, yahoo_id: yahoo_id, owner: owner }
  end

  def owner_data(ownership_data)
    case ownership_data['ownership_type']
    when 'freeagents'
      'Free Agent'
    when 'waivers'
      'On Waivers'
    when 'team'
      ownership_data['owner_team_name']
    end
  end

  def parse_ownership_response(response)
    league_data = response['fantasy_content']['league']
    if league_data.is_a? Array
      parse_array_ownership_data(league_data)
    elsif league_data.is_a? Hash
      parse_hash_ownership_data(league_data)
    else
      raise StandardError, "Ownership data is not Hash/Array, it is a(n) #{league_data.class}"
    end
  end

  def ownership_check(ids, league = test_values[:league_key])
    uri = ownership_path(ids, league)
    response = get uri
    parse_ownership_response(response)
  end

  def league_key(league_id)
    "mlb.l.#{league_id}"
  end

  def fantasy_team_key(league_id, team_id)
    "mlb.l.#{league_id}.t.#{team_id}"
  end

  def player_key(player_id)
    "mlb.p.#{player_id}"
  end

  def player_keys(player_ids)
    player_ids.map { |pid| player_key(pid) }.join(',')
  end

  def test_values
    { league_id: 88_700,
      team_id: 7,
      league_key: league_key(88_700),
      team_key: fantasy_team_key(88_700, 7),
      player: 10_843,
      player_ids: [10_843, 12_118],
      player_key: player_key(10_843) }
  end

  def league_uri(opts = {})
    key = opts[:league_key] || league_key(opts[:league_id])
    "https://fantasysports.yahooapis.com/fantasy/v2/league/#{key}" + (opts[:teams] ? '/teams' : '')
  end

  def team_uri(opts = {})
    base = 'https://fantasysports.yahooapis.com/fantasy/v2/team/'
    base += opts[:team_key] || fantasy_team_key(opts[:league_id], opts[:team_number])
    base += '/roster' if opts[:roster]
    base
  end

  def get_teams_from_league(league_id)
    uri = league_uri({ league_id: league_id, teams: true })
    response = get uri
    league = response['fantasy_content']['league']
    league['teams']['team']
  end

  def get_team_roster_data(opts = {})
    team_key = opts[:team_key] || fantasy_team_key(opts[:league_id], opts[:team_number])
    uri_options = { team_key: team_key, roster: true }
    uri = team_uri(uri_options)
    response = get uri
    team_data = response['fantasy_content']['team']
    { team_key: team_key, team_name: team_data['name'], roster: team_data['roster']['players']['player'] }
  end

  def get_roster_data(opts = {})
    unless (team_keys = opts[:team_keys]) && opts[:league_id]
      team_keys = get_teams_from_league(opts[:league_id]).map { |team| team['team_key'] }
    end
    rosters = []
    team_keys.each do |key|
      rosters << get_team_roster_data({ team_key: key })
    end
    # parse_rosters(rosters)
    rosters
  end
end

if __FILE__ == $0
  yahoo = YahooAPI.new
  league_id = 88_700
  binding.pry
  all_rosters = yahoo.get_roster_data({ league_id: league_id })
end
