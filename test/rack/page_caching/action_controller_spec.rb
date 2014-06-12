require 'action_controller'
require "rack/page_caching/action_controller"
require 'test_helper'

class TestController < ActionController::Metal
  def index
    self.response_body = 'test'
  end
end

describe Rack::PageCaching::ActionController do
  include Rack::Test::Methods

  def app
    Rack::Builder.new {
      map '/' do
        use Rack::PageCaching,
          :page_cache_directory => 'something',
          :include_hostname => true
        run TestController.action(:index)
      end
    }.to_app
  end

  it 'does something' do
    get '/'
    puts last_response.inspect
    assert last_response.ok?
  end
end
