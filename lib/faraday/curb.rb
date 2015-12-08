require 'faraday/adapter/curb'
Faraday::Adapter.register_middleware :curb => lambda { Faraday::Adapter::Curb }
