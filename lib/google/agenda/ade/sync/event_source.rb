require "icalendar"

require "google/agenda/ade/sync/base"

module Google::Agenda::Ade::Sync
  module EventSource
    # Loads events from the first calendar of an UTF-8 encoded ICS file
    def self.load_events(ics_file)
      File.open(ics_file, encoding: 'utf-8') do |cal_file|
        return Icalendar.parse(cal_file).first.events
      end
    end
  end
end