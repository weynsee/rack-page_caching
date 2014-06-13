require 'fileutils'

module FileHelper
  def self.included(base)
    base.class_eval do
      let(:cache_path) do
        path = ::File.join(::File.dirname(__FILE__), '/../tmp/', 'cache')
        File.expand_path path
      end

      before do
        FileUtils.rm_rf(::File.dirname(cache_path))
        FileUtils.mkdir_p(cache_path)
      end

      #after { FileUtils.rm_rf(::File.dirname(cache_path)) }
    end
  end
end
