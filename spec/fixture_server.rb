require 'webrick'

# Serve files from the spec/fixtures folder as http://localhost:8000/

# ICS fixture files are assumed to be UTF-8 for testing
WEBrick::HTTPUtils::DefaultMimeTypes['ics'] = 'text/calendar; charset=utf-8'

# Configure and start server
server = WEBrick::HTTPServer.new(
  :Port => 8000,
  :DocumentRoot => File.expand_path('./spec/fixtures')
)
server.start
