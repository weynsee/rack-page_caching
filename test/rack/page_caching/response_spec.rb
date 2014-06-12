require 'test_helper'

describe Rack::PageCaching::Response do
  let(:rack_response) do
    [
      200,
      { 'Content-Type' => 'text/html; charset=utf-8' },
      ['Foo Bar']
    ]
  end

  let(:env) do
    {
      'PATH_INFO' => '/hotels/singapore',
      'REQUEST_METHOD' => 'GET',
      'HTTP_HOST' => 'www.example.org',
      'rack.page_caching.perform_caching' => true
    }
  end

  let(:response) { Rack::PageCaching::Response.new(rack_response, env) }

  it 'is cacheable for successful html responses' do
    response.cacheable?.must_equal true
  end

  it 'returns the path' do
    response.path.must_equal '/hotels/singapore'
  end

  it 'returns the body' do
    response.body.must_equal ['Foo Bar']
  end

  it 'returns the content type' do
    response.content_type.must_equal 'text/html'
  end

  it 'returns the host' do
    response.host.must_equal 'www.example.org'
  end

  describe 'no caching' do
    describe 'no directive provided' do
      before { env.delete 'rack.page_caching.perform_caching' }
      it 'is not cacheable by default' do
        response.cacheable?.must_equal false
      end
    end

    describe 'directive is false' do
      before { env.merge! 'rack.page_caching.perform_caching' => false }
      it 'is not cacheable if perform_caching env is set to false' do
        response.cacheable?.must_equal false
      end
    end

    describe 'response not cacheable' do
      before { env.merge! 'REQUEST_METHOD' => 'POST' }
      it 'does not cache post requests' do
        response.cacheable?.must_equal false
      end
    end

    describe 'non-200 response' do
      before { rack_response[0] = 404 }
      it 'does not cache resposes where status is not 200' do
        response.cacheable?.must_equal false
      end
    end
  end
end
