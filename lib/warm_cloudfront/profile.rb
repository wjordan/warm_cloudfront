require 'hashdiff'

module WarmCloudfront
  CLOUDFRONT_LOCATIONS = YAML.load_file(File.join(__dir__, 'edge.yml'))['cloudfront']

  def self.profile(full_profile = false)
    valid_locations = {}
    hydra = Typhoeus::Hydra.new
    keys = full_profile ? CLOUDFRONT_LOCATIONS.keys : CLOUDFRONT_LOCATIONS
    keys.each do |location, edges|
      iterator = full_profile ? (1..60) : edges
      iterator.each do |x|
        request = Typhoeus::Request.new(
          "http://www.profile.#{location}#{x}.cloudfront.net",
          method: 'HEAD'
        )
        request.on_complete do |response|
          @progress_bar.increment
          (valid_locations[location] ||= []).push(x) if response.code == 200
        end
        hydra.queue request
      end
    end
    total = hydra.queued_requests.length
    @progress_bar = ProgressBar.create(
      title: 'Profiling',
      total: total,
      format: '%t %c/%C|%b>>%i| %p%%'
    )
    hydra.run
    valid_locations.values.map(&:sort!)
    valid_count = valid_locations.values.flatten.length
    if valid_count != CLOUDFRONT_LOCATIONS.values.flatten.count
      Warm.log.info "Found #{valid_count} / #{total} CloudFront locations."
      missing, new = diff(CLOUDFRONT_LOCATIONS, valid_locations)
      Warm.log.info "Missing locations: #{missing}" if missing
      Warm.log.info "New locations: #{new}" if new
    else
      Warm.log.info 'Found all CloudFront locations.'
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
