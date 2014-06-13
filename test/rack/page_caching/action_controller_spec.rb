require 'action_controller'
require "rack/page_caching/action_controller"
require 'test_helper'
require './test/support/file_helper'

class TestController < ActionController::Base
  caches_page :with_domain
  caches_page :just_head, if: Proc.new { |c| !c.request.format.json? }
  caches_page :redirect_somewhere

  def with_domain
    render text: 'foo bar'
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
      map '/with_domain' do
        use Rack::PageCaching, options.merge(include_hostname: true)
        run TestController.action(:with_domain)
      end
      [:just_head, :redirect_somewhere, :custom_caching].each do |action|
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

  it 'saves to a file with the domain as a folder' do
    get 'http://www.test.org/with_domain'
    set_path 'www.test.org', 'with_domain.html'
    assert File.exist?(cache_file), 'with_domain.html should exist'
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
end
