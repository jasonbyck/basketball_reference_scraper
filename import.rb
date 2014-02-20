require 'nokogiri'
require 'open-uri'
require_relative 'teams'

# Convert split 'sports type' dates into valid dates
# IE. converts 2013-14 (ie. the season starting in 2013 and ending in 2014) to a valid date
# Use the date the year ended
def converted_date(date)
  split_date = date.split('-')
  first_year = split_date.first.to_i
  first_year + 1
end

def reference_url(code)
  "http://www.basketball-reference.com/teams/#{code}"
end

def metadata_for_team(team)
  dataset_code = team[:code]
  dataset_name = "NBA Team Statistics - #{team[:name]}"
  dataset_description = "Historical Team Statistics of the #{team[:name]}"
  metadata = <<META
  code: #{dataset_code}
  name: #{dataset_name}
  description: #{dataset_description}
  reference_url: #{reference_url(team[:short_code])}
META
end

def data_for_team(team)
  doc = Nokogiri::HTML(open(reference_url(team[:short_code])))
  csv = "Year, Wins, Losses, ORtg, DRtg\n"
  records = doc.css("#div_#{team[:short_code]}")
  records.xpath('.//tbody//tr').each_with_index do |row, i|
    next if i == 0 # Skip first row (active season)
    # Date
    date = row.xpath('.//td/a')[0].content
    # Wins
    wins = row.xpath('.//td')[3].content
    # Losses
    loss = row.xpath('.//td')[4].content
    # Offensive Rating
    ortg = row.xpath('.//td')[10].content
    # Defensive Rating
    lrtg = row.xpath('.//td')[12].content
    # Convert 2012-13 to 2013 - ie. the year the season ended
    csv << "#{converted_date(date)}, #{wins}, #{loss}, #{ortg}, #{lrtg}\n"
  end
  csv
end

NBA_TEAMS.each do |team|

  metadata = metadata_for_team(team)
  puts metadata
  puts '---'
  
  if metadata.empty?
    puts "Missing metadata for #{team[:name]}!"
    exit
  end
  
  data = data_for_team(team)
  
  if data.empty? or data.lines.count < 2
    puts "Missing data for #{team[:name]}!"
    exit
  end
  
  puts data
  puts ''
  
end



