module Rack
  class PageCaching
    module ActionController
      extend ActiveSupport::Concern

      module ClassMethods
        def caches_page(*actions)
          return unless perform_caching
          options = actions.extract_options!
          gzip_level = options.fetch(:gzip, Zlib::BEST_COMPRESSION)
          gzip_level = Rack::PageCaching::Utils.gzip_level(gzip_level)
          after_filter({ only: actions }.merge(options)) do |c|
            c.request.env['rack.page_caching.perform_caching'] = true
            c.request.env['rack.page_caching.compression'] = gzip_level
          end
        end
      end

      def expire_page(options = {})
        return unless self.class.perform_caching

        if options.is_a?(Hash)
          if options[:action].is_a?(Array)
            options[:action].each do |action|
              Rack::PageCaching::Cache.delete(url_for(options.merge(only_path: true, action: action)))
            end
          else
            Rack::PageCaching::Cache.delete(url_for(options.merge(only_path: true)))
          end
        else
          Rack::PageCaching::Cache.delete(options)
        end
      end

      def cache_page(content = nil, options = nil, gzip = Zlib::BEST_COMPRESSION)
        return unless self.class.perform_caching

        path = case options
          when Hash
            url_for(options.merge(only_path: true, format: params[:format]))
          when String
            options
          else
            request.path
        end
        path = path.chomp('/')

        if (type = ::Mime::LOOKUP[self.content_type]) && (type_symbol = type.symbol).present?
          path = "#{path}.#{type_symbol}" unless /#{type_symbol}\z/.match(path)
        end

        Rack::PageCaching::Cache.write_file(
          Array(content || response.body), path,
          Rack::PageCaching::Utils.gzip_level(gzip)
        )
      end
    end
  end
end

ActionController::Base.send(:include, Rack::PageCaching::ActionController)
