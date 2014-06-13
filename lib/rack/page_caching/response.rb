require 'rack/request'

module Rack
  class PageCaching
    class Response
      def initialize(response, env)
        @response, @env = response, env
      end

      def cacheable?
        perform_caching? && caching_allowed?
      end

      def path
        @path ||= request.path
      end

      def body
        @response[2]
      end

      def content_type
        @response[1]['Content-Type'].split(';').first
      end

      def gzip_level
        @env['rack.page_caching.compression'].to_i if @env['rack.page_caching.compression']
      end

      def host
        request.host
      end

      private

      def request
        @request ||= Rack::Request.new(@env)
      end

      def caching_allowed?
        method = @env['REQUEST_METHOD']
        (method == 'GET' || method == 'HEAD') && @response[0] == 200
      end

      def perform_caching?
        @env['rack.page_caching.perform_caching'].to_s == 'true'
      end
    end
  end
end
