require 'warm_cloudfront/warm'
require 'warm_cloudfront/profile'

module WarmCloudfront
  def self.new(cloudfront_id, host)
    Warm.new(cloudfront_id, host)
  end
end
