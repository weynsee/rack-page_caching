require 'test_helper'
require 'pathname'

describe Rack::PageCaching::Environment do
  let(:env) { Rack::PageCaching::Environment.new(options) }

  describe 'defaults' do
    let(:options) { {} }

    it 'is not enabled when a page_cache_directory is not set' do
      refute env.enabled?
    end

    it 'defaults page_cache_compression to false' do
      refute env.page_cache_compression
    end

    it 'defaults include_hostname to false' do
      refute env.include_hostname?
    end
  end

  describe 'set options' do
    let(:options) {
      {
        include_hostname: true,
        page_cache_compression: :best_compression,
        page_cache_directory: '/var/tmp'
      }
    }

    it 'includes hostname' do
      env.include_hostname?.must_equal true
    end

    it 'is enabled' do
      env.enabled?.must_equal true
    end

    it 'returns the correct zlib compression constant' do
      env.page_cache_compression.must_equal Zlib::BEST_COMPRESSION
    end

    it 'sets the correct page cache directory' do
      env.page_cache_directory.must_equal '/var/tmp'
    end

    describe 'page_cache_directory' do
      before { options.merge! page_cache_directory: Pathname.new('/var/tmp') }

      it 'accepts a Pathname as page cache directory' do
        env.page_cache_directory.must_equal '/var/tmp'
      end
    end
  end

  describe 'in Rails' do
    before do
      controller = Object.new
      controller.define_singleton_method(:perform_caching) { true }
      config = Object.new
      config.define_singleton_method(:action_controller) { controller }
      application = Object.new
      application.define_singleton_method(:config) { config }
      root = Object.new
      root.define_singleton_method(:join) do |folder|
        Pathname.new('/var/www/app').join(folder)
      end
      Rails = Class.new
      Rails.define_singleton_method(:application) { application }
      Rails.define_singleton_method(:root) { root }
    end

    let(:options) { {} }

    it 'sets the page cache path to public folder relative to rails root' do
      env.page_cache_directory.must_equal '/var/www/app/public'
    end

    after { Object.send(:remove_const, :Rails) }
  end
end
