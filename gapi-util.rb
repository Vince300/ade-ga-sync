# MIT License
# 
# Copyright (c) 2016 Vincent TAVERNIER
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'time'
require 'google/api_client'

module GAPIUtil
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