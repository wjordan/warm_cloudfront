require 'hashdiff'
require 'resolv'
require 'parallel'

module WarmCloudfront
  CLOUDFRONT_LOCATIONS = YAML.load_file(File.join(__dir__, 'edge.yml'))['cloudfront']

  def self.profile(full_profile = false)
    valid_locations = {}
    keys = full_profile ? CLOUDFRONT_LOCATIONS.keys : CLOUDFRONT_LOCATIONS
    resolv = Resolv::DNS.new(:nameserver => ['8.8.8.8', '8.8.4.4'])
    total = full_profile ? keys.length * 60 : keys.values.flatten.length
    Parallel.each(keys, progress: 'Profiling', in_threads: 100) do |location, edges|
      iterator = full_profile ? (1..60) : edges
      iterator.each do |x|
        request = resolv.getaddress("www.profile.#{location}#{x}.cloudfront.net") rescue nil
        if request
          (valid_locations[location] ||= []).push(x)
        end
      end
    end
    valid_locations.values.map(&:sort!)
    valid_count = valid_locations.values.flatten.length
    if valid_count != CLOUDFRONT_LOCATIONS.values.flatten.count
      Warm.log.info "Found #{valid_count} / #{total} CloudFront locations."
      missing, new = diff(CLOUDFRONT_LOCATIONS, valid_locations)
      Warm.log.info "Missing locations: #{missing}" if missing
      Warm.log.info "New locations: #{new}" if new
    else
      Warm.log.info "Found all #{total} CloudFront locations."
    end
  end

  def self.diff(old, new)
    diff = HashDiff.diff(old, new).group_by{|x|x[0]}
    %w(- +).map do |x|
      diff[x] && diff[x].map do |m|
        m.slice! 0
        m[0].gsub!(/\[\d+\]/,'')
        m.join('')
      end
    end
  end
end
