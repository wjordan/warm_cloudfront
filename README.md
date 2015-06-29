# WarmCloudfront

This library warms up CloudFront caches with your origin server's objects.
Provide your CloudFront subdomain id (e.g., `abcdefg1234567` if your CloudFront distribution's Domain Name is `abcdefg1234567.cloudfront.net`) and a list of paths, and warm_cloudfront will send
GET requests for each path to [every active CloudFront edge location server](https://github.com/wjordan/warm_cloudfront/blob/master/lib/warm_cloudfront/edge.yml),
ensuring that your objects will be cached at all CloudFront edge locations for future requests.

## Installation

Install with Bundler by adding this line to your application's Gemfile:

```ruby
gem 'warm_cloudfront'
```

And then execute:

    $ bundle

Or install it directly with RubyGems:

    $ gem install warm_cloudfront

## Usage

Run the `warm_cloudfront` executable:

    $ warm_cloudfront
    Usage: warm_cloudfront {cloudfront_subdomain} {path1} [{path2}] ...

Or, use the `WarmCloudfront` class in your Ruby code, e.g.:

```ruby
require 'warm_cloudfront'
WarmCloudfront.new('cloudfrontidstring').warm(['/', '/assets/my_new_asset.txt'])
```

## Development

After checking out the repo, run `bundle install` to install dependencies, then hack away.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/wjordan/warm_cloudfront).

## License

[MIT](http://opensource.org/licenses/MIT)
