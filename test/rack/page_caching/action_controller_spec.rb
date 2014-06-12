require 'action_controller'
require "rack/page_caching/action_controller"
require 'test_helper'
require './test/support/file_helper'

class TestController < ActionController::Base
  caches_page :index

  def index
    render text: 'foo bar'
  end
end

describe Rack::PageCaching::ActionController do
  include Rack::Test::Methods
  include FileHelper

  def app
    path = cache_path
    Rack::Builder.new {
      map '/' do
        use Rack::PageCaching,
          :page_cache_directory => path,
          :include_hostname => true
        run TestController.action(:index)
      end
    }.to_app
  end

  let(:cache_file) { File.join(cache_path, 'www.test.org', 'index.html') }

  it 'does something' do
    get 'http://www.test.org/'
    assert File.exist?(cache_file)
    File.read(cache_file).must_equal 'foo bar'
  end
end
