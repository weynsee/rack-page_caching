module Rack
  class PageCaching
    module Utils
      def self.gzip_level(gzip)
        case gzip
        when Symbol
          Zlib.const_get(gzip.to_s.upcase)
        when Fixnum
          gzip
        else
          false
        end
      end
    end
  end
end
