require "icalendar"
require "open-uri"

require "google/agenda/ade/sync/base"

module Google::Agenda::Ade::Sync
  class EventSource
    def initialize(ics_file, start_date = nil, end_date = nil)
      @ics_file = ics_file
      @start_date = start_date
      @end_date = end_date
    end

    # Loads events from the configured source file
    # Configured path may be an URL using open-uri
    def load_events
      # Default to UTF-8 on local files
      if File.exist? @ics_file
        open(@ics_file, encoding: 'utf-8') do |cal_file|
          return parse_file(cal_file)
        end
      else
        # Loaded events
        events = []

        if @start_date.nil?
          events.concat get_events(@ics_file)
        else
          # Step through all dates
          current_start = @start_date
          @start_date.step(@end_date, 7).drop(1).each do |ed|
            say "Exporting agenda (#{current_start} to #{ed})"

            # ICS URL
            dtfmt = '%Y-%m-%d'
            full_ics = "#{@ics_file}&firstDate=#{current_start.strftime(dtfmt)}&lastDate=#{ed.strftime(dtfmt)}"

            # Parse into events
            events.concat get_events(full_ics)

            # Next bound
            current_start = ed + 1
          end
        end

        return events
      end
    end

    def to_s
      return "(ics) #{@ics_file}"
    end

    private
      def get_events(full_ics)
        open(full_ics) do |cal_file|
          return parse_file(cal_file)
        end
      end

      def parse_file(cal_file)
        return Icalendar.parse(cal_file).first.events
      end
  end
end