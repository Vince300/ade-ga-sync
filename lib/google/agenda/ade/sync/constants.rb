require "google/agenda/ade/sync/base"
require "google/agenda/ade/sync/version"

module Google::Agenda::Ade::Sync
  # Path to the Google API client secret storage
  API_CREDENTIALS_FILE = 'calendar-oauth2.json'
  OAUTH_TOKEN_FILE = 'credentials.json'

  # Settings for the Google API
  GOOGLE_API_APPNAME = 'google-agenda-ade-sync'
  GOOGLE_API_APPVERS = VERSION

  # Path to the configuration file
  CONFIGURATION_FILE = 'ade-ga-sync.json'
end