class ProbablePitchers
  require_relative 'models/players'
  attr_accessor :start_date, :end_date, :dates, :pitchers

  def initialize
    reset!
  end

  def pp_url
    url = "https://statsapi.mlb.com/api/v1/schedule?sportId=1&hydrate=probablePitcher&startDate=#{ProbablePitchers.start_date}"
    url += "&endDate=#{@end_date}" if @end_date
    puts "PP MLB URL: #{url}"
    url
  end

  def http_call
    httparty = HTTParty.get pp_url
    # create a nice bash table of pitchers

    # Assuming the response is stored in the `httparty` variable
    JSON.parse(httparty.body)
  rescue StandardError => e
    puts "An error occurred during the HTTP request: #{e}"
    # You can handle the error here, such as logging or returning a default value
    # For now, let's return an empty array
    []
  end

  def league_url(addendum)
    "https://baseball.fantasysports.yahoo.com/b1/88700/#{addendum}"
  end

  def player_url(addendum)
    "https://sports.yahoo.com/mlb/players/#{addendum}"
  end

  def self.start_date
    Date.today
  end

  def reset!
    @end_date = Date.today
    @dates = []
    @pitchers = []
  end

  def extract_pitchers(dates)
    dates.each do |date|
      games = date['games']
      games.each do |game|
        [game['teams']['home'], game['teams']['away']].each do |team|
          pitcher_data = team['probablePitcher']
          next unless pitcher_data

          pitcher_name = pitcher_data['fullName']
          pitcher = Players.find_by_full_name(pitcher_name)
          @pitchers << pitcher if pitcher
        end
      end
    end
    @pitchers
  end
end
