# ruby script to get my getpocket links from last week

require 'pocket_api'
require 'awesome_print'
require 'io/console'
require 'date'
require 'active_support'
require 'active_support/core_ext/object/blank'
require 'byebug'

class Pocket
  # API_KEY is called 'Consumer Key' on developer page
  # https://getpocket.com/developer/app/89547/5e7e2c4ed6c247854c98e7ad
  API_KEY = ENV['POCKET_API_KEY']
  TOKEN = ENV['POCKET_ACCESS_TOKEN']

  class << self

    # get links from Pocket API
    def links(options)
      PocketApi.configure(client_key: Pocket::API_KEY,
                          access_token: Pocket::TOKEN)
      items = PocketApi.retrieve(options)
      puts "Found #{items.keys.size} results..."
      parsed_links = []
      items.values.each do |link|
        parsed_links << parse_link(link)
      end
      return parsed_links
    rescue => e
      puts "API call failed with: #{e.message}"
      puts e.backtrace.join("\n")
      raise e
    end

    # parse link response that we get from API
    def parse_link(link)
      return {
        title: link['given_title'],
        url: link['given_url'],
        excerpt: link['excerpt'],
        resolved_title: link['resolved_title'],
        resolved_url: link['resolved_url'],
        created_at: Time.at(link['time_added'].to_i).utc,
        updated_at: Time.at(link['time_updated'].to_i).utc,
        comment: ''
      }
    end

    # get access token from the API, needs API KEY
    # Flow:
    # 1. Set api key
    # 2. build auth URL
    # 3. open auth url
    def access_token
      PocketApi::Connection.client_key = API_KEY
      auth_url = PocketApi::Connection.generate_authorize_url('https://suraj.dev')
      puts "Open #{auth_url} in browser and allow application"
      puts 'press any key once done..'
      STDIN.getch
      token = PocketApi::Connection.generate_access_token
      ap "access_token: #{token}"
      return token
    end

    def days_ago_unix_ts(days)
      days_in_seconds = days * 86400
      now_unix_seconds = Time.now.utc.to_i
      return now_unix_seconds - days_in_seconds
    end

    def intro_text
      "Hello :wave:,\n"\
      "Welcome to another edition of reading list\n"\
      "Here are things that I have been reading and found interesting\n"\
      'Read away !!! :book:'
    end

    def outro_text
      string = "Hope it was interesting, and you enjoyed reading it\n"\
               "Share what you have been reading with me via twitter @electron0zero\n"\
               "Cya :wave:\n"
      return string
    end
  end
end

# get token, and ad dit in env file if current one expires
# token = Pocket.access_token

# see list: https://getpocket.com/developer/docs/v3/retrieve
LOOK_BACK_DAYS = 7
since_ts = Pocket.days_ago_unix_ts(LOOK_BACK_DAYS)
options = { state: 'all',
            sort: 'newest',
            detailType: 'simple',
            since:  since_ts }
items = Pocket.links(options)
date = Date.today.iso8601
reading_list = {
  date: date,
  time: Time.now.utc.to_s,
  options: options,
  items: items
}

file_name = "reading_list_#{date}.json"
puts "Saving results in #{file_name}"
file = File.open(file_name, 'wb')
# to pretty print JSON
file.write(JSON.pretty_generate(reading_list))
file.close
puts 'Done'
