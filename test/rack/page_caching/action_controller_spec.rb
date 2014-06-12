require 'action_controller'
require "rack/page_caching/action_controller"
require 'test_helper'
require './test/support/file_helper'

class TestController < ActionController::Base
  def index
    render text: 'test'
    cache_page 'testing', 'test_file'
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

  it 'does something' do
    get '/'
    assert last_response.ok?
  end
end
