require 'typhoeus'
require 'resolv'
require 'yaml'
require 'ruby-progressbar'
require 'parallel'

module WarmCloudfront
  class Warm
    CLOUDFRONT_EDGES = YAML.load_file(File.join(__dir__, 'edge.yml'))['cloudfront']

    def initialize(cloudfront_id, host)
      @domains = CLOUDFRONT_EDGES.map do |edge, zones|
        zones.map do |zone|
          "#{cloudfront_id}.#{edge.downcase}#{zone}.cloudfront.net"
        end
      end.flatten
      @host = host
      @warmed = 0
      @errors = 0
      @headers = {}
    end

    def warm(paths)
      requests = paths.map do |path|
        path = "/#{path}" if path[0] != '/'
        @domains.map do |domain|
          request(domain, path)
        end
      end.flatten

      total = requests.length
      @progress_bar = ProgressBar.create(
        title: 'Warming',
        total: total,
        format: '%t %c/%C|%b>>%i| %p%%'
      )
      Parallel.each(requests, in_threads: 100) do |request|
        request.run
      end
      log.info "Warmed #{total} objects: #{@warmed} cache misses, #{total-@warmed-@errors} cache hits#{", #{@errors} errors" if @errors.nonzero?}."
      log.info 'Results:'
      log_header('Age')

      %w(ETag Content-Length Last-Modified).each do |field|
        if @headers.values.map{|h| h[field]}.uniq.length > 1
          log.warn "#{field} inconsistent!"
          log_header field
        end
      end
    end

    def request(domain, path)
      url = "https://#{@host}#{path}"
      address = Resolv::DNS.new(nameserver: %w(8.8.8.8 8.8.4.4)).getaddress(domain)
      request = Typhoeus::Request.new(
        url,
        resolve: Ethon::Curl.slist_append(nil,
          "#{@host}:443:#{address}"
        ),
        # CF separately caches GET and HEAD responses, so we must send GET requests
        headers: {
          Host: @host,
          'Accept-Encoding' => 'gzip' # CF separately caches gzip requests from non-gzip requests
        },
        timeout: 5
      )
      request.on_headers do |response|
        @progress_bar.increment
        if response.code == 200
          @headers[domain] = response.headers
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
      request.on_failure do |response|
        if response.code != 200
          log.error "Failure: #{response.return_message}"
          @errors += 1
        end
      end

      request.on_body do |_|
        # We don't need to download the full body, just the headers.
        :abort
      end
      request
    end

    def log_header(field)
      log.info "Edge\t#{field}"
      @headers.sort.each do |domain, results|
        puts "#{domain.split('.')[1].upcase}\t#{results[field] || '-'}"
      end
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
