require 'action_controller'
require "rack/page_caching/action_controller"
require 'test_helper'
require './test/support/file_helper'

class TestController < ActionController::Base
  caches_page :with_domain
  caches_page :ok, if: Proc.new { |c| !c.request.format.json? }

  def with_domain
    render text: 'foo bar'
  end

  def ok
    head :ok
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
      map '/ok' do
        use Rack::PageCaching, options
        run TestController.action(:ok)
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
    head '/ok'
    set_path 'ok.html'
    assert File.exist?(cache_file), 'head response should have been cached'
  end
end
