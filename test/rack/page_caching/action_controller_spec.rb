require 'action_controller'
require "rack/page_caching/action_controller"
require 'test_helper'
require './test/support/file_helper'

class TestController < ActionController::Base
  caches_page :cache
  caches_page :just_head, if: Proc.new { |c| !c.request.format.json? }
  caches_page :redirect_somewhere
  caches_page :no_gzip, gzip: false
  caches_page :gzip_level, gzip: :best_speed
  caches_page :accept_xml

  def cache
    render text: 'foo bar'
  end

  def no_gzip
    render text: 'no gzip'
  end

  def just_head
    head :ok
  end

  def redirect_somewhere
    redirect_to '/just_head'
  end

  def custom_caching
    render text: 'custom'
    cache_page('Cache rules everything around me', 'wootang.html')
  end

  def without_extension
    render text: 'without extension'
    cache_page('Path without extension', 'without_extension')
  end

  def gzip_level
    render text: 'level up'
  end

  def accept_xml
    respond_to do |format|
      format.html { render text: 'I am html' }
      format.xml  { render text: 'I am xml'  }
    end
  end
end

describe Rack::PageCaching::ActionController do
  include Rack::Test::Methods
  include FileHelper

  def app
    options = {
      page_cache_directory: cache_path,
      include_hostname: false
    }
    Rack::Builder.new {
      map '/with-domain' do
        use Rack::PageCaching, options.merge(include_hostname: true)
        run TestController.action(:cache)
      end
      [:cache, :just_head, :redirect_somewhere, :custom_caching,
       :no_gzip, :gzip_level, :without_extension, :accept_xml].each do |action|
        map "/#{action}" do
          use Rack::PageCaching, options
          run TestController.action(action)
        end
      end
    }.to_app
  end

  def set_path(*path)
    @cache_path = [cache_path].concat path
  end

  let(:cache_file) { File.join(*@cache_path) }

  it 'caches the requested page and creates gzipped file by default' do
    get '/cache'
    set_path 'cache.html'
    assert File.exist?(cache_file), 'cache.html should exist'
    File.read(cache_file).must_equal 'foo bar'
    assert File.exist?(File.join(cache_path, 'cache.html.gz')),
      'gzipped cache.html file should exist'
    assert last_request.env['rack.page_caching.compression'] == Zlib::BEST_COMPRESSION,
      'compression level must use config gzip by default'
  end

  it 'saves to a file with the domain as a folder' do
    get 'http://www.test.org/with-domain'
    set_path 'www.test.org', 'with-domain.html'
    assert File.exist?(cache_file), 'with-domain.html should exist'
    File.read(cache_file).must_equal 'foo bar'
  end

  it 'caches head request' do
    head '/just_head'
    set_path 'just_head.html'
    assert File.exist?(cache_file), 'head response should have been cached'
  end

  it 'will not cache when http status is not 200' do
    get '/redirect_somewhere'
    assert_cache_folder_is_empty
  end

  it 'caches custom text to a custom path' do
    get '/custom_caching'
    set_path 'wootang.html'
    assert File.exist?(cache_file), 'wootang.html should exist'
    File.read(cache_file).must_equal 'Cache rules everything around me'
  end

  it 'caches paths that do not have extensions' do
    get '/without_extension'
    set_path 'without_extension.html'
    assert File.exist?(cache_file), 'without_extension.html should exist'
  end

  it 'does not create a gzip file when gzip argument is false' do
    get '/no_gzip'
    set_path 'no_gzip.html'
    assert File.exist?(cache_file), 'no_gzip.html should exist'
    refute File.exist?(File.join(cache_path, 'no_gzip.html.gz')),
      'gzipped no_gzip.html file should not exist'
  end

  it 'allows overriding of gzip level' do
    get '/gzip_level'
    assert last_request.env['rack.page_caching.compression'] == Zlib::BEST_SPEED,
      'compression level must be set to the requested level'
  end

  it 'caches by http accept attribute' do
    get '/accept_xml', {}, { 'HTTP_ACCEPT' => 'text/xml' }
    set_path 'accept_xml.xml'
    #assert File.exist?(cache_file), 'accept_xml.xml should exist'
  end
end
