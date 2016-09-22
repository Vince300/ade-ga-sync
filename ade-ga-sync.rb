# MIT License
# 
# Copyright (c) 2016 Vincent TAVERNIER
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'date'
require 'icalendar'
require 'open-uri'
require 'trollop'
require 'yaml'

# Google API Client
gem 'google-api-client', '0.8.6'
require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/file_storage'
require 'google/api_client/auth/installed_app'
require_relative './gapi-util'

# Path to the downloaded iCal file from ADE
CALENDAR_FILE = 'calendar.ics'

# Path to the Google API client secret storage
SECRETS_STORE_FILE = 'calendar-oauth2.json'
CREDENTIALS_FILE = 'credentials.json'

# Settings for the Google API
GOOGLE_API_APPNAME = 'ade-ga-sync'
GOOGLE_API_APPVERS = '0.1'

# Path to the configuration file
CONFIGURATION_FILE = 'ade-ga-sync.yml'

# On 32-bit Ruby installs, Unix timestamps are created as Bignum instances, 
# which was not supported by the Ruby Google API client. This should be fixed
# one day, but here we just patch the method.
module Signet
  module OAuth2
    class Client
      alias_method :o_normalize_timestamp, :normalize_timestamp
      def normalize_timestamp(time)
        case time
        when NilClass
          nil
        when Time
          time
        when String
          Time.parse(time)
        when Fixnum, Bignum
          #Adding Bignum ^ here as timestamps like 1453983084 are bignums on 32-bit systems
          Time.at(time)
        else
          fail "Invalid time value #{time}"
        end
      end
    end
  end
end

# This tool works from the directory the script is run from.
Dir.chdir File.dirname(__FILE__)
puts "Tool directory: #{Dir.pwd}"

# Parse command line options
opts = Trollop::options do
  opt :blank, "Dry-run, do not update Google Agenda"
end

# Load tool config
config = YAML::load(File.read(CONFIGURATION_FILE, encoding: 'utf-8'))

# Download ICS file from ADE
url = config['ics'][0]
puts "Downloading calendar from #{url}..."
File.open(CALENDAR_FILE, 'wb') do |outf|
  open(url, 'rb') do |inf|
    outf.write(inf.read)
  end
end

# Parse ICS. The Icalendar gem aborts execution if there is a syntax
# error because of a corrupted download.
puts "Parsing calendar..."
ics = nil
File.open(CALENDAR_FILE, encoding: 'utf-8') do |cal_file|
  ics = Icalendar.parse(cal_file).first
end

puts "Found #{ics.events.length} events"

# Authorize Google Agenda
calendar_name = config['calendar']

client = Google::APIClient.new(:application_name => GOOGLE_API_APPNAME,
                               :application_version => GOOGLE_API_APPVERS)

# FileStorage stores auth credentials in a file, so they survive multiple runs
# of the application. This avoids prompting the user for authorization every
# time the access token expires, by remembering the refresh token.
# Note: FileStorage is not suitable for multi-user applications.
file_storage = Google::APIClient::FileStorage.new(CREDENTIALS_FILE)
if file_storage.authorization.nil?
  client_secrets = Google::APIClient::ClientSecrets.load(SECRETS_STORE_FILE)
  # The InstalledAppFlow is a helper class to handle the OAuth 2.0 installed
  # application flow, which ties in with FileStorage to store credentials
  # between runs.
  flow = Google::APIClient::InstalledAppFlow.new(
    :client_id => client_secrets.client_id,
    :client_secret => client_secrets.client_secret,
    :scope => ['https://www.googleapis.com/auth/calendar']
  )
  client.authorization = flow.authorize(file_storage)
else
  client.authorization = file_storage.authorization
end

service = client.discovered_api('calendar', 'v3')

# Find calendar
puts "Trying to access calendar #{calendar_name}..."
GAPIUtil.on_result result = client.execute(:api_method => service.calendar_list.list,
                                           :parameters => { 'minAccessRole' => 'writer' })

calendar = result.data.items.select { |cal| cal['summary'] == calendar_name }.first

if calendar
  puts "Found calendar with id #{calendar.id}"
else
  puts "Calendar #{calendar_name} not found"
  exit 1
end

requests = []

# Create event creation requests
ics.events.each do |e|
  gcal_event = {
    'start' => {
      'dateTime' => e.dtstart.rfc3339
    },
    'end' => {
      'dateTime' => e.dtend.rfc3339
    },
    'summary' => e.summary,
    'location' => e.location,
    'description' => e.description,
    # 'iCalUID' => e.uid, # skipped because it was inconsistent on ADE
    'sequence' => e.sequence
  }

  requests << {
    :api_method => service.events.insert,
    :parameters => {
      'calendarId' => calendar.id
    },
    :body_object => gcal_event
  }
end

# Find events to delete, starting today
GAPIUtil.on_result result = client.execute(:api_method => service.events.list,
                                           :parameters => { 'calendarId' => calendar.id,
                                                            'timeMin' => Date.today.to_datetime.rfc3339 })

# Parse results and append event deletion requests to the list of pending requests
page_token = ""
while not page_token.nil?
  result.data.items.select { |event| event.status != 'cancelled' }.each do |event|
    requests << {
      :api_method => service.events.delete,
      :parameters => { 'calendarId' => calendar.id,
                       'eventId' => event.id }
    }
    puts "Found #{event.summary}"
  end

  # Event data is paginated
  page_token = result.data.next_page_token
  if page_token
    GAPIUtil.on_result result = client.execute(:api_method => service.events.list,
                                               :parameters => { 'calendarId' => calendar.id,
                                                                'pageToken' => page_token })
  end
end

# Send requests, unless this is a dry-run
unless opts[:blank]
  requests.reverse!
  GAPIUtil.send_requests(client, requests)
  puts "Done!"
end