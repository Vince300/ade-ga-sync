require "commander/import"
require "launchy"

# Google API Client
require "google/apis/calendar_v3"
require "googleauth"
require "googleauth/stores/file_token_store"

# ADE Sync dependencies
require "google/agenda/ade/sync/base"
require "google/agenda/ade/sync/constants"
require "google/agenda/ade/sync/event_source"

OOB_URI = "urn:ietf:wg:oauth:2.0:oob"
SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR

module Google::Agenda::Ade::Sync
  module EntryPoint
    # Authorize the Google API user
    def self.authorize(client_secrets, credentials)
      client_id = Google::Auth::ClientId.from_file(client_secrets)
      token_store = Google::Auth::Stores::FileTokenStore.new(file: credentials)
      authorizer = Google::Auth::UserAuthorizer.new(
        client_id, SCOPE, token_store)
      user_id = 'default'
      credentials = authorizer.get_credentials(user_id)
      if credentials.nil?
        url = authorizer.get_authorization_url(
          base_url: OOB_URI)
        say "Your default browser should open so you can authorize this tool " +
            "to edit your Google Calendar data."
        say "If your browser didn't open, follow this link manually."
        say url

        # Open default browser
        Launchy.open(url)

        code = ask('Enter the authentication code you received: ')
        fail "aborted" if code.nil? or code.empty?
        credentials = authorizer.get_and_store_credentials_from_code(
          user_id: user_id, code: code, base_url: OOB_URI)
      end
      credentials
    end

    # Find a calendar by its name
    def self.find_calendar_by_name(client, name)
      page_token = nil
      begin
        result = client.list_calendar_lists(page_token: page_token)
        result.items.each do |e|
          if e.summary == name
            return e
          end
        end

        if result.next_page_token != page_token
          page_token = result.next_page_token
        else
          page_token = nil
        end
      end while !page_token.nil?
      nil
    end

    # Return events to delete
    def self.get_events_to_delete(client, calendar_id, start_at)
      events = []

      page_token = nil
      begin
        result = client.list_events(calendar_id,
                                    time_min: start_at.rfc3339,
                                    page_token: page_token)
        result.items.each do |e|
          say "Found event in Google Calendar: #{e.summary}"
          events << e
        end
        if result.next_page_token != page_token
          page_token = result.next_page_token
        else
          page_token = nil
        end
      end while !page_token.nil?
      events
    end

    def self.run(dry_run, config, credentials_file, token_file)
      # Download ICS file from ADE
      url = config['ics']

      say "Loading events from #{url}..."
      ics_events = load_events(url)

      # Print status about read events
      say "Found #{ics_events.length} events"

      # Authorize Google Agenda
      calendar_name = config['calendar']

      client = Google::Apis::CalendarV3::CalendarService.new
      client.client_options.application_name = "ade-ga-sync"
      client.authorization = authorize(credentials_file, token_file)

      # Load calendar
      say "Trying to access calendar #{calendar_name}..."
      calendar = find_calendar_by_name(client, calendar_name)

      if calendar
        say "Found calendar with id #{calendar.id}"
      else
        fail "Calendar #{calendar_name} not found"
      end

      # Find obsolete events
      old_events = get_events_to_delete(client, calendar.id, Date.today.to_datetime)

      unless dry_run
        client.batch do |client|
          # Delete all events
          old_events.each do |e|
            client.delete_event(calendar.id, e.id) do
              say "Removed #{e.id}"
            end
          end

          # Create event creation requests
          ics_events.each do |e|
            gcal_event = Google::Apis::CalendarV3::Event.new(
              summary: e.summary,
              location: e.location,
              description: e.description,
              sequence: e.sequence,
              start: {
                date_time: e.dtstart.rfc3339
              },
              end: {
                date_time: e.dtend.rfc3339
              })

            client.insert_event(calendar.id, gcal_event) do
              say "Created #{gcal_event.summary}"
            end
          end
        end
      end
    end

    def self.load_events(url)
      return EventSource.new(url).load_events
    end
  end
end