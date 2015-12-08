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

        method = env[:method].upcase.to_sym
        url = env[:url].to_s
        post_body = env[:body] if method == :POST
        put_body = env[:body] if method == :PUT || method == :PATCH
        client = ::Curl.http(method, url, post_body, put_body) do |c|
          c.headers = env[:request_headers]

          # Configure ssl
          if env[:url].scheme == 'https' && ssl = env[:ssl]
            if ssl[:verify] == false
              c.ssl_verify_peer = false
              c.ssl_verify_host = 0
            end
          end

          # Set timeout
          req = env[:request]
          c.timeout          = req[:timeout] if req[:timeout]
          c.connect_timeout  = req[:open_timeout] if req[:open_timeout]
        end

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
