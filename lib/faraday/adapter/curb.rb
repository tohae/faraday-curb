module Faraday
  class Adapter
    class Curb < Faraday::Adapter
      dependency 'curb'

      def call(env)
        super
        perform_request env
        @app.call env
      end

      private

      def perform_request(env)
        read_body env

        client = ::Curl::Easy.new(env[:url].to_s) do |c|
          c.headers = env[:request_headers]
        end

        configure_timeout(client, env)

        client.send(*(["http_#{env[:method]}", env[:body]].compact))
        save_response(env, client.response_code, client.body_str, parse_header_string(client.header_str).last)
      rescue Curl::Err::ConnectionFailedError => e
        raise Faraday::Error::ConnectionFailed, e
      rescue Curl::Err::TimeoutError => e
        raise Faraday::Error::TimeoutError, e
      end

      def read_body(env)
        env[:body] = env[:body].read if env[:body].respond_to? :read
      end

      def configure_timeout(client, env)
        req = env[:request]
        client.timeout          = req[:timeout] if req[:timeout]
        client.connect_timeout  = req[:open_timeout] if req[:open_timeout]
      end

      # Borrowed from Webmock's Curb adapter:
      # http://github.com/bblimke/webmock/blob/master/lib/webmock/http_lib_adapters/curb.rb
      def parse_header_string(header_string)
        status, headers = nil, {}
        return [status, headers] unless header_string

        header_string.split(/\r\n/).each do |header|
          if header =~ %r|^HTTP/1.[01] \d\d\d (.*)|
            status = $1
          else
            parts = header.split(':', 2)
            unless parts.empty?
              parts[1].strip! unless parts[1].nil?
              if headers.has_key?(parts[0])
                headers[parts[0]] = [headers[parts[0]]] unless headers[parts[0]].kind_of? Array
                headers[parts[0]] << parts[1]
              else
                headers[parts[0]] = parts[1]
              end
            end
          end
        end

        [status, headers]
      end

    end
  end
end
