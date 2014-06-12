require "rack/page_caching/version"
require "rack/page_caching/utils"
require "rack/page_caching/environment"
require "rack/page_caching/response"
require "rack/page_caching/cache"
require "rack/page_caching/mime_types"

require "rack/page_caching/action_controller" if defined?(::Rails)

module Rack
  class PageCaching

    MimeTypes.load!
    MimeTypes.register 'text/html', '.html'
    MimeTypes.register 'text/plain', '.txt'

    def initialize(app, options = {})
      @app = app
      self.class.environment = Rack::PageCaching::Environment.new(options)
    end

    def call(env)
      rack_response = @app.call(env)
      if self.class.environment.enabled?
        response = Rack::PageCaching::Response.new(rack_response, env)
        Rack::PageCaching::Cache.store(response) if response.cacheable?
      end
      rack_response
    end

    class << self
      attr_accessor :environment
    end
  end
end
