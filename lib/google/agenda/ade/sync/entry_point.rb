require "date"
require "open-uri"
require "yaml"
require "tempfile"

require "trollop"

# Google API Client
require "google/api_client"
require "google/api_client/client_secrets"
require "google/api_client/auth/file_storage"
require "google/api_client/auth/installed_app"

# ADE Sync dependencies
require "google/agenda/ade/sync/base"
require "google/agenda/ade/sync/constants"
require "google/agenda/ade/sync/event_source"

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

module Google::Agenda::Ade::Sync
  module EntryPoint
    def self.run
      # Parse command line options
      opts = Trollop::options do
        opt :n, "Dry-run, do not update Google Agenda"
      end

      # Load tool config
      config = YAML::load(File.read(CONFIGURATION_FILE, encoding: 'utf-8'))

      # Download ICS file from ADE
      url = config['ics'][0]

      puts "Loading events from #{url}..."
      ics_events = load_events(url)

      # Print status about read events
      puts "Found #{ics_events.length} events"

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
      GapiUtil.on_result result = client.execute(:api_method => service.calendar_list.list,
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
      ics_events.each do |e|
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
      GapiUtil.on_result result = client.execute(:api_method => service.events.list,
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
          GapiUtil.on_result result = client.execute(:api_method => service.events.list,
                                                    :parameters => { 'calendarId' => calendar.id,
                                                                      'pageToken' => page_token })
        end
      end

      # Send requests, unless this is a dry-run
      unless opts[:n]
        requests.reverse!
        GapiUtil.send_requests(client, requests)
        puts "Done!"
      end
    end

    private
      def self.load_events(url)
        return EventSource.new(url).load_events
      end
  end
end