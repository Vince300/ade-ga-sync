require "time"
require "google/api_client"

require "google/agenda/ade/sync/base"

module Google::Agenda::Ade::Sync
  module GapiUtil
    # Process a result from the Google Data API. For now we just print out the
    # error message, but more error handling can be done.
    def self.on_result(result)
      if result.error?
        puts "An error occured: #{result.error_message}"
      end
      result.error?
    end

    # Sends requests to the Google Data API using the maximum batch size, while
    # ensuring we don't overrun the requests/second limit on the API.
    # 
    # The result of each request is passed to the block if present.
    def self.send_requests(client, requests)
      while requests.length > 0
        puts "#{requests.length} requests left"
        batch = Google::APIClient::BatchRequest.new do |result|
            on_result(result)
            yield result if block_given?
        end

        requests.take(50).each do |request|
            batch.add(request)
        end
        
        t1 = Time.now
        client.execute(batch)
        t2 = Time.now

        requests.slice!(0, 50)

        sleep(5.5 - (t2 - t1)) if requests.length > 0
      end
    end
  end
end
