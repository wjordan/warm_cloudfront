# boilerplate
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'warm_cloudfront/version'

Gem::Specification.new do |s|
  s.name        = 'warm_cloudfront'
  s.version     = WarmCloudfront::VERSION
  s.date        = '2015-06-28'
  s.summary     = 'Warms up your CloudFront cache'
  s.authors     = ['Will Jordan']
  s.files       = Dir['lib/**/*.*'] + Dir['bin/*']
  s.license     = 'MIT'
  s.add_dependency 'typhoeus', '~> 0.7'
  s.add_dependency 'ruby-progressbar', '~> 1.7'
  s.executables << 'warm_cloudfront'

  s.add_development_dependency 'bundler', '~> 1.10'
  s.add_development_dependency 'rake', '~> 10.0'
end
