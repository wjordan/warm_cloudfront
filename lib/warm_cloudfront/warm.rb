require 'typhoeus'
require 'yaml'
require 'ruby-progressbar'

module WarmCloudfront
  class Warm
    CLOUDFRONT_EDGES = YAML.load_file(File.join(__dir__, 'edge.yml'))['cloudfront']

    def initialize(cloudfront_id)
      @domains = CLOUDFRONT_EDGES.map do |edge, zones|
        "#{cloudfront_id}.#{edge.downcase}.cloudfront.net"
      end
      @host = "#{cloudfront_id}.cloudfront.net"
      @warmed = 0
      @errors = 0
    end

    def warm(paths)
      hydra = Typhoeus::Hydra.new
      paths.each do |path|
        path = "/#{path}" if path[0] != '/'
        @domains.each do |domain|
          req = request("#{domain}#{path}")
          hydra.queue req
        end
      end

      total = hydra.queued_requests.length
      @progress_bar = ProgressBar.create(
        title: 'Warming',
        total: total,
        format: '%t %c/%C|%b>>%i| %p%%'
      )
      hydra.run
      log.info "Warmed #{total} objects: #{@warmed} cache misses, #{total-@warmed-@errors} cache hits#{", #{@errors} errors" if @errors.nonzero?}."
    end

    def request(url)
      request = Typhoeus::Request.new(
        url,
        # CF separately caches GET and HEAD responses, so we must send GET requests
        headers: {
          Host: @host,
          'Accept-Encoding' => 'gzip' # CF separately caches gzip requests from non-gzip requests
        }
      )
      request.on_headers do |response|
        @progress_bar.increment
        if response.code == 200
          @warmed += 1 if response.headers['X-Cache'] == 'Miss from cloudfront'
        elsif response.timed_out?
          log.warn "Timeout from #{url}"
          @errors += 1
        elsif response.code == 0
          # Could not get an http response, something's wrong.
          log.warn "No response from #{url}: #{response.return_message}"
          @errors += 1
        else
          # Received a non-successful http response.
          log.warn "HTTP request failed from #{url}: #{response.code.to_s}"
          @errors += 1
        end
      end
      request.on_body do |_|
        # We don't need to download the full body, just send the GET request
        :abort
      end
      request
    end

    def log
      self.class.log
    end
    # Simple default logger implementation
    class << self
      attr_writer :log
      def log
        class_variable_defined?(:@@log)?
          class_variable_get(:@@log):
          (self.log = Logger.new(STDOUT).tap do |l|
            l.level = Logger::INFO
            l.formatter = proc do |severity, _, _, msg|
              "#{severity != 'INFO' ? "#{severity}: " : ''}#{msg}\n"
            end
          end)
      end
    end
  end
end
