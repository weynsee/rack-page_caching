# Rack::PageCaching

[![Gem Version](https://badge.fury.io/rb/rack-page_caching.svg)](http://badge.fury.io/rb/rack-page_caching)
[![Build Status](https://travis-ci.org/weynsee/rack-page_caching.svg?branch=master)](https://travis-ci.org/weynsee/rack-page_caching)
[![Coverage Status](https://img.shields.io/coveralls/weynsee/rack-page_caching.svg)](https://coveralls.io/r/weynsee/rack-page_caching?branch=master)
[![Dependency Status](https://gemnasium.com/weynsee/rack-page_caching.svg)](https://gemnasium.com/weynsee/rack-page_caching)

Rack::PageCaching is a Rack middleware that aids in static page caching. It serves
the same purpose as [Rails page caching](https://github.com/rails/actionpack-page_caching) 
and was designed to be a drop-in replacement for it.

Rack::PageCaching provides a few differences from Rails page caching. It is
implemented as a Rack middleware, which means transformations done on the 
response by other middlewares will be present in the generated static page.
Examples of middlewares that work well with page caching include 
[htmlcompressor](https://github.com/paolochiodi/htmlcompressor) and 
[rack-pjax](https://github.com/eval/rack-pjax).
Implementing it in Rack also  means that it can also be used in other 
Rack-compatible frameworks like Sinatra.

While it was designed to be a drop-in replacement for Rails page caching, it
provides additional features like including the hostname in the path of the
generated static page.

## Installation

Add this line to your application's Gemfile:

    gem 'rack-page_caching'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack-page_caching

Tell your app to use the Rack::PageCaching middleware.
For Rails 3+ apps:

```ruby
# In config/application.rb
config.middleware.use Rack::PageCaching
```

Or for Rackup files:

```ruby
# In config.ru
use Rack::PageCaching
```

When you want page caching to be applied to a response modified by other
middlewares, make sure you place Rack::PageCaching *before* those 
middlewares.

It has been tested on Rails 3 and 4, and on Ruby 1.9.3 and 2.x.

## Usage

Rack::PageCaching accepts all the options accepted by Rails page caching: 
```ruby
config.middleware.use Rack::PageCaching,
  # Directory where the pages are stored. Defaults to the public folder in
  # Rails, but you'll probably want to customize this
  page_cache_directory: Rails.root.join('public', 'page_cache'),
  # Gzipped version of the files are generated with compression level
  # specified. It accepts the symbol versions of the constants in Zlib,
  # e.g. :best_speed and :best_compression. To turn off gzip, pass in false.
  gzip: :best_speed,
  # Hostnames can be included in the path of the page cache. Default is false.
  include_hostname: true
```
Rack::PageCaching respects `config.action_controller.perform_caching` and
will skip cache generation if it is false.

To configure your web server to serve the generated pages directly, point it to
`page_cache_directory`. For Nginx, it would look something like the following
if you include hostnames:
```
if (-f $document_root/page_cache/$host/$uri/index.html) {
  rewrite (.*) /page_cache/$host/$1/index.html break;
}

if (-f $document_root/page_cache/$host/$uri.html) {
  rewrite (.*) /page_cache/$host/$1.html break;
}
```

Rack::PageCaching implements the same class methods Rails page caching provides, 
so if you were using it previously you can leave it as is:
```ruby
class WeblogController < ActionController::Base
  caches_page :show, :new
end
```
Expiration is also supported the same way:
```ruby
class WeblogController < ActionController::Base
  def update
    List.update(params[:list][:id], params[:list])
    expire_page action: 'show', id: params[:list][:id]
    redirect_to action: 'show', id: params[:list][:id]
  end
end
```
You can delete pages manually (e.g. in a rake task) using the following command:
```ruby
Rack::PageCaching::Cache.delete 'weblog/*.html'
# if you have hostnames enabled, use '**/weblog/*.html' to delete regardless
# of which hostname the files are nested in
```

## Acknowledgements

Tests for compatibility with Rails page caching and ActionController integration
were heavily inspired by code in the 
[Rails page caching gem](https://github.com/rails/actionpack-page_caching).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/rack-page_caching/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
