require 'faraday/adapter/curb'
Faraday::Adapter.register_middleware File.expand_path('../adapter', __FILE__), :curb => [:Curb, 'curb']
