module Curl
  class Easy
    def http_patch
      self.http :PATCH
    end
    alias patch http_patch
  end
end

require 'faraday/adapter/curb'
Faraday::Adapter.register_middleware :curb => lambda { Faraday::Adapter::Curb }
