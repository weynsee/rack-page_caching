require 'rack/mime'

module Rack
  class PageCaching
    class MimeTypes
      def self.load!
        mime_types = Rack::Mime::MIME_TYPES
        extensions = Hash.new { |hash, key| hash[key] = [] }
        mime_types.each do |extension, content_type|
          extensions[content_type] << extension
        end
        @extension_lookup = extensions
      end

      def self.register(content_type, extension)
        @extension_lookup[content_type] = [extension]
      end

      def self.extension_for(content_type)
        @extension_lookup[content_type].first
      end
    end
  end
end
