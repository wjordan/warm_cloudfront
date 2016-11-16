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
  s.add_dependency 'typhoeus'
  s.add_dependency 'parallel'
  s.add_dependency 'ruby-progressbar'
  s.add_dependency 'hashdiff'
  s.executables << 'warm_cloudfront'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
end
