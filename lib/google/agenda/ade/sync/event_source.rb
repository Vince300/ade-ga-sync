require "icalendar"
require "open-uri"

require "google/agenda/ade/sync/base"

module Google::Agenda::Ade::Sync
  class EventSource
    def initialize(ics_file)
      @ics_file = ics_file
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
        # Open using default open (maybe open-uri)
        open(@ics_file) do |cal_file|
          return parse_file(cal_file)
        end
      end
    end

    def to_s
      return "(ics) #{@ics_file}"
    end

    private
      def parse_file(cal_file)
        return Icalendar.parse(cal_file).first.events
      end
  end
end