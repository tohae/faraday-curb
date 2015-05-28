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

        configure_ssl(client, env)
        configure_timeout(client, env)

        arguments = ["http_#{env[:method]}"]
        if [:patch, :put, :post].include? env[:method]
          arguments << (env[:body] || "")
        end

        client.send(*arguments)

        save_response(env, client.response_code, client.body_str, parse_headers(client.header_str))
      rescue Curl::Err::ConnectionFailedError => e
        raise Faraday::Error::ConnectionFailed, e
      rescue Curl::Err::SSLCACertificateError, Curl::Err::SSLPeerCertificateError => e
        raise Faraday::Error::SSLError, e
      rescue Curl::Err::TimeoutError => e
        raise Faraday::Error::TimeoutError, e
      end

      def read_body(env)
        env[:body] = env[:body].read if env[:body].respond_to? :read
      end

      def configure_ssl(client, env)
        if env[:url].scheme == 'https' && ssl = env[:ssl]
          if ssl[:verify] == false
            client.ssl_verify_peer = false
            client.ssl_verify_host = 0
          end
        end
      end

      def configure_timeout(client, env)
        req = env[:request]
        client.timeout          = req[:timeout] if req[:timeout]
        client.connect_timeout  = req[:open_timeout] if req[:open_timeout]
      end

      # Borrowed from Patron:
      # https://github.com/toland/patron/blob/master/lib/patron/response.rb
      def parse_headers(header_data)
        headers = {}

        header_data.split(/\r\n/).each do |header|
          unless header =~ %r|^HTTP/1.[01]|
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

        headers
      end

    end
  end
end
