module Rack
  class PageCaching
    class Environment
      def initialize(options = {})
        @options = options
        set_defaults
      end

      def page_cache_compression
        @options[:page_cache_compression]
      end

      def page_cache_directory
        @options[:page_cache_directory]
      end

      def include_hostname?
        @options[:include_hostname]
      end

      def enabled?
        @options[:enable]
      end

      def instrument(name, path)
        if defined? ActiveSupport::Notifications
          ActiveSupport::Notifications.instrument("#{name}.action_controller", path: path) do
            yield
          end
        else
          yield
        end
      end

      private

      def set_defaults
        set_rails_defaults if defined? ::Rails
        normalize_values
        toggle_caching
      end

      def normalize_values
        @options.merge!(
          page_cache_compression: Rack::PageCaching::Utils.gzip_level(
            @options[:page_cache_compression]),
          page_cache_directory: @options[:page_cache_directory].to_s,
        )
      end

      def toggle_caching
        @options[:enable] = false if @options[:page_cache_directory].strip == ''
        @options[:enable] = true unless @options.has_key?(:enable)
      end

      def set_rails_defaults
        @options = {
          page_cache_directory: ::Rails.root.join('public'),
          enable: ::Rails.application.config.action_controller.perform_caching
        }.merge(@options)
      end
    end
  end
end
