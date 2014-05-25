require 'test_helper'

describe Rack::PageCaching::MimeTypes do
  let(:mime_types) { Rack::PageCaching::MimeTypes }

  describe '.extension_for' do
    {
      'text/html' => '.html',
      'application/json' => '.json',
      'text/css' => '.css'
    }.each do |content_type, extension|
      it "returns #{extension} for content type #{content_type}" do
        mime_types.extension_for(content_type).must_equal extension
      end
    end
  end

  describe '.register' do
    it 'allows registration of custom content_type' do
      mime_types.register 'text/ing', '.ing'
      mime_types.extension_for('text/ing').must_equal '.ing'
    end
  end
end
