require "icalendar"
require "mechanize"
require "commander"

require "google/agenda/ade/sync/base"

module Google::Agenda::Ade::Sync
  class AdeEventSource
    include Commander::Methods

    def initialize(username, password, target_url, start_date, end_date)
      @username = username
      @password = password
      @target_url = target_url
      @start_date = start_date
      @end_date = end_date
    end

    # Loads events from the remote ADE source
    def load_events
      agent = Mechanize.new
      agent.user_agent_alias = "Windows Mozilla"
      agent.add_auth(@target_url, @username, @password)

      say "Loading #{@target_url}..."
      # Fetch the calendar welcome page
      calendar_page = agent.get(@target_url).forms.first.submit

      say "Loading export page..."
      # Reach for the "Export Agenda" link
      export_page = calendar_page
        .frame_with(:name => 'link').click
        .link_with(:href => 'icalDates.jsp?clearTree=false').click

      # Exported events
      events = []

      current_start = @start_date
      @start_date.step(@end_date, 7).drop(1).each do |ed|
        say "Exporting agenda (#{current_start} to #{ed})"

        # The export form
        form = export_page.form('formPDF')

        # Fill out fields
        form.startDay = current_start.day
        form.startMonth = current_start.month
        form.startYear = current_start.year
        form.endDay = ed.day
        form.endMonth = ed.month
        form.endYear = ed.year
        
        # Submit the form, generates the ICS as a response
        ics_page = form.submit
        body = ics_page.body
        body.force_encoding('UTF-8')

        # Add parsed events
        events.concat Icalendar.parse(body).first.events

        # Update next bound
        current_start = ed + 1
      end

      # Parse returned ICS
      return events
    end

    def to_s
      "(ADE) #{@username}@#{@target_url}"
    end
  end
end