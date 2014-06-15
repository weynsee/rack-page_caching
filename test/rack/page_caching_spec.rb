require 'test_helper'
require 'rack/test'
require './test/support/file_helper'

describe Rack::PageCaching do
  include Rack::Test::Methods
  include FileHelper

  def app
    path = cache_path
    rack_response = response
    Rack::Builder.new {
      use Rack::PageCaching,
        page_cache_directory: path,
        include_hostname: true
      run lambda { |env| rack_response }
    }.to_app
  end

  describe 'invalid response' do
    before do
      get 'http://www.fakeuri.org/hello', {},
        { 'rack.page_caching.perform_caching' => 'true' }
    end

    let(:response) do
      [
        404,
        { 'Content-Type' => 'text/html' },
        ['Not found']
      ]
    end

    it 'does not create a file' do
      assert_cache_folder_is_empty
    end
  end

  describe 'valid response' do
    before { get 'http://www.fakeuri.org/hello', {}, env }
    let(:env) { {} }
    let(:cache_file) { File.join(cache_path, 'www.fakeuri.org', 'hello.html') }
    let(:response) do
      [
        200,
        { 'Content-Type' => 'text/html' },
        ['Foo Bar']
      ]
    end

    describe 'request caching' do
      let(:env) { { 'rack.page_caching.perform_caching' => 'true' } }

      it 'creates a file after the request' do
        File.exist?(cache_file).must_equal true
        File.read(cache_file).must_equal 'Foo Bar'
      end

      describe 'compression' do
        let(:env) do
          {
            'rack.page_caching.perform_caching' => 'true',
            'rack.page_caching.compression' => Rack::PageCaching::Utils.gzip_level(:best_speed)
          }
        end

        it 'creates a compressed file after the request' do
          cache = File.join(cache_path, 'www.fakeuri.org', 'hello.html.gz')
          File.exist?(cache).must_equal true
          Zlib::GzipReader.open(cache) do |gz|
            gz.read.must_equal 'Foo Bar'
          end
        end
      end
    end

    it 'skips creation of file if caching is not needed' do
      refute File.exist?(cache_file)
    end
  end
end
