require 'spec_helper'

describe Google::Agenda::Ade::Sync::EventSource do
  describe 'local event loading' do
    before(:all) do
      url = './spec/fixtures/short_calendar.ics'
      @source = Google::Agenda::Ade::Sync::EventSource.new(url)
    end

    before (:each) do
      @events = @source.load_events
    end

    it 'loads .ics files and returns events' do
      expect(@events.length).to eq 1
      expect(@events[0].summary).to eq 'Anglais'
    end

    it 'supports utf-8 characters' do
      expect(@events[0].description).to match 'EXPORTÉ'
    end
  end

  describe 'remote event loading' do
    before (:all) do
      @source = Google::Agenda::Ade::Sync::EventSource.new('http://localhost:8000/short_calendar.ics')
    end

    before (:each) do
      @events = @source.load_events
    end

    it 'loads .ics files from remote hosts' do
      expect(@events.length).to eq 1
    end

    it 'supports utf-8 characters from remote files' do
      expect(@events[0].description).to match 'EXPORTÉ'
    end
  end
end