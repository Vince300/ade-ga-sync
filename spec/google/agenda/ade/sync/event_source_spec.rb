require 'spec_helper'

describe Google::Agenda::Ade::Sync::EventSource do
  describe 'load_events' do
    before(:all) do
      @events = Google::Agenda::Ade::Sync::EventSource.load_events('./spec/fixtures/short_calendar.ics')
    end

    it 'loads .ics files and returns events' do
      expect(@events.length).to eq 1
      expect(@events[0].summary).to eq 'Anglais'
    end

    it 'supports utf-8 characters' do
      expect(@events[0].description).to match 'EXPORTÉ'
    end
  end
end