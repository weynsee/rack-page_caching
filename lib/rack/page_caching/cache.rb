require 'fileutils'
require 'zlib'

module Rack
  class PageCaching
    class Cache
      def initialize(response)
        @response = response
      end

      def store
        if path = page_cache_path
          self.class.write_file(@response.body, path, gzip_level)
        end
      end

      def page_cache_path
        path = Rack::Utils.unescape(@response.path.chomp('/'))
        if !path.include?('..')
          type = Rack::PageCaching::MimeTypes.extension_for @response.content_type
          path = '/index' if path.empty?
          path = "#{path}#{type}" unless /#{Regexp.quote(type)}\z/.match(path)
          path = "/#{@response.host}#{path}"  if config.include_hostname?
          path
        end
      end

      def gzip_level
        @response.gzip_level || config.page_cache_compression
      end

      def self.store(response)
        Rack::PageCaching::Cache.new(response).store
      end

      def self.write_file(content, path, gzip_level)
        expand_path('write_page', path) do |full_path|
          FileUtils.makedirs(::File.dirname(full_path))
          ::File.open(full_path, 'wb+') { |f| content.each { |c| f.write(c) } }
          if gzip_level
            Zlib::GzipWriter.open(full_path + '.gz', gzip_level) do |f|
              content.each do |c|
                f.write(c)
              end
            end
          end
        end
      end

      def self.delete(path)
        expand_path('expire_page', path) do |full_path|
          Dir[full_path].each do |file|
            ::File.delete(file)
            ::File.delete(file + '.gz') if ::File.exist?(file + '.gz')
          end
        end
      end

      private

      def self.expand_path(name, path)
        env = Rack::PageCaching.environment
        full_path = ::File.join(env.page_cache_directory, path)
        env.instrument name, full_path do
          yield full_path
        end
      end

      def config
        Rack::PageCaching.environment
      end
    end
  end
end
