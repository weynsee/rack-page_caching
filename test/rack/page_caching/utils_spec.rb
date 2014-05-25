require 'test_helper'

describe Rack::PageCaching::Utils do
  let(:utils) { Rack::PageCaching::Utils }
  describe '.gzip_level' do
    it 'accepts a number and returns it' do
      utils.gzip_level(1).must_equal 1
    end

    it 'accepts a symbol and returns the corresponding zlib constant' do
      utils.gzip_level(:best_speed).must_equal Zlib::BEST_SPEED
    end

    it 'returns false for unrecognized input' do
      utils.gzip_level('best_speed').must_equal false
    end
  end
end
