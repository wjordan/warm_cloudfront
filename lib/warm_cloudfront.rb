require 'warm_cloudfront/warm'
require 'warm_cloudfront/profile'

module WarmCloudfront
  def self.new(cloudfront_id)
    Warm.new(cloudfront_id)
  end
end
