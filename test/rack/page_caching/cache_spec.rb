require 'test_helper'
require './test/support/file_helper'

describe Rack::PageCaching::Cache do
  let(:options) { {} }

  let(:config) { Rack::PageCaching::Environment.new(options) }

  let(:content_type) { 'text/html' }

  let(:path) { '/hotels/singapore' }

  let(:env) do
    {
      'PATH_INFO' => path,
      'REQUEST_METHOD' => 'GET',
      'HTTP_HOST' => 'www.example.org',
      'rack.page_caching.perform_caching' => true
    }
  end

  let(:response) do
    Rack::PageCaching::Response.new(
      [
        200,
        { 'Content-Type' => content_type },
        ['Foo Bar']
      ],
      env
    )
  end

  let(:cache) { Rack::PageCaching::Cache.new(response) }

  before { Rack::PageCaching.environment = config }

  describe '#gzip_level' do
    subject { cache.gzip_level }

    describe 'from config' do
      let(:options) { { page_cache_compression: :best_compression } }

      it 'returns the gzip_level from config if gzip level is not specified in response' do
        subject.must_equal Zlib::BEST_COMPRESSION
      end
    end

    describe 'from response' do
      before do
        env.merge! 'rack.page_caching.compression' => Rack::PageCaching::Utils.gzip_level(:best_speed)
        options.merge! page_cache_compression: :best_compression
      end

      it 'returns the gzip_level from response' do
        subject.must_equal Zlib::BEST_SPEED
      end
    end
  end

  describe '#page_cache_path' do
    subject { cache.page_cache_path }

    it 'returns the correct page_cache_path' do
      subject.must_equal '/hotels/singapore.html'
    end

    describe 'uses correct extension' do
      let(:content_type) { 'application/xml' }
      it 'returns the correct extension for the cache path' do
        subject.must_equal '/hotels/singapore.xml'
      end
    end

    describe 'uses index.html' do
      let(:path) { '/' }

      it 'appends index.html when path is only a slash' do
        subject.must_equal '/index.html'
      end
    end

    describe 'uses hostname' do
      before { options.merge!(include_hostname: true) }

      it 'includes hostname in cache path' do
        subject.must_equal '/www.example.org/hotels/singapore.html'
      end
    end

    describe 'skips extension' do
      let(:path) { '/index.json' }
      let(:content_type) { 'application/json' }

      it 'does not add extension again if path already has extension' do
        subject.must_equal '/index.json'
      end
    end

    describe 'escapes path' do
      let(:path) { '/path%20with%20spaces' }

      it 'escapes the path' do
        subject.must_equal '/path with spaces.html'
      end
    end
  end

  describe 'saving to disk' do
    include FileHelper

    let(:options) { { page_cache_directory: cache_path } }
    let(:cache_file) { File.join(cache_path, 'hotels', 'singapore.html') }
    let(:cache_content) { File.read(cache_file) }

    describe '#store' do
      it 'stores the response to disk' do
        cache.store
        cache_content.must_equal 'Foo Bar'
      end

      it 'overwrites the file for the same call' do
        cache.store
        cache.store
        cache_content.must_equal 'Foo Bar'
      end

      describe 'compression' do
        let(:options) do
          {
            page_cache_compression: :best_speed,
            page_cache_directory:  cache_path,
          }
        end

        let(:zipped_path) { File.join(cache_path, 'hotels', 'singapore.html.gz') }

        it 'creates a compressed file' do
          cache.store
          File.exist?(zipped_path).must_equal true
        end

        it 'zips the content' do
          cache.store
          Zlib::GzipReader.open(zipped_path) do |gz|
            gz.read.must_equal 'Foo Bar'
          end
        end
      end
    end

    describe '.store' do
      it 'stores the response to disk' do
        Rack::PageCaching::Cache.store(response)
        cache_content.must_equal 'Foo Bar'
      end
    end

    describe '.delete' do
      it 'stores the file to disk' do
        Rack::PageCaching::Cache.store(response)
        File.exist?(cache_file).must_equal true
        Rack::PageCaching::Cache.delete(File.join('hotels', 'singapore.html'))
        refute File.exist?(cache_file)
      end

      describe 'globs' do
        let(:options) do
          {
            page_cache_directory:  cache_path,
            include_hostname: true
          }
        end

        let(:cache_file) do
          File.join(cache_path, 'www.example.org', 'hotels', 'singapore.html')
        end

        it 'accepts globs in path' do
          Rack::PageCaching::Cache.store(response)
          File.exist?(cache_file).must_equal true
          Rack::PageCaching::Cache.delete(File.join('**', 'hotels', 'singapore.html'))
          refute File.exist?(cache_file)
        end
      end
    end
  end
end
