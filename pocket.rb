# ruby script to get my getpocket links from last week

require 'pocket_api'
require 'awesome_print'
require 'io/console'
require 'active_support'
require 'active_support/core_ext/object/blank'
require 'byebug'

class Pocket
  # API_KEY is called 'Consumer Key' on developer page
  # https://getpocket.com/developer/app/89547/5e7e2c4ed6c247854c98e7ad
  API_KEY = ENV['POCKET_API_KEY']
  TOKEN = ENV['POCKET_ACCESS_TOKEN']
  class << self
    def links(since: )
      PocketApi.configure(client_key: Pocket::API_KEY, access_token: Pocket::TOKEN)
      # see list: https://github.com/electron0zero/pocket_api/blob/master/lib/pocket_api.rb#L17
      opts = { state: 'all',
               sort: 'newest',
               detailType: 'simple',
               count: '100' }
      items = PocketApi.retrieve(opts)
      return items
    rescue => e
      ap "Call failed with: #{e}"
      ap e.backtrace
      return nil
    end

    # get access token from the API
    # Flow:
    # 1. Set api key
    # 2. build auth URL
    # 3. open auth url
    def access_token
      # going to fetch it
      PocketApi::Connection.client_key = API_KEY
      auth_url = PocketApi::Connection.generate_authorize_url('https://suraj.dev')
      puts "Open #{auth_url} in browser and allow application"
      puts 'press any key once done..'
      STDIN.getch
      token = PocketApi::Connection.generate_access_token
      ap "access_token: #{token}"
      return token
    end
  end
end

# get token if current one expires
# token = Pocket.access_token

items = Pocket.links(since: 2.days)
# get items
sliced_items = []
items.values.each do |item|
  item = item.slice(
    'given_url', 'given_title', 'resolved_title', 'resolved_url', 'excerpt', 'time_added', 'time_updated')
  sliced_items << item
end
