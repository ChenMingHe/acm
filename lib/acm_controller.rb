require 'acm/rack_monkey_patch'

require "acm/config"
require "acm/api_controller"

require "sequel"
require "yajl"

module ACM::Controller

  # Main application controller that receives all requests and passes them on to
  # the ApiController (Sinatra) for handling
  class RackController
    PUBLIC_URLS = ["/info"]

    def initialize
      super
      @logger = ACM::Config.logger
      api_controller = ApiController.new

      @logger.debug("Created ApiController")

      #Configure basic auth for all urls
      @app = Rack::Auth::Basic.new(api_controller) do |username, password|
        [username, password] == [ACM::Config.basic_auth[:user], ACM::Config.basic_auth[:password]]
      end
      @app.realm = "ACM"

    end

    # Rack requires the controller to respond to this message
    def call(env)

      @logger.debug("Request env #{env.inspect}")
      request = Rack::Request.new(env)
      @logger.debug("Incoming request #{request.request_method} #{request.url}")

      start_time = Time.now
      status, headers, body = @app.call(env)
      end_time = Time.now
      @logger.debug("Done request #{request.request_method} #{request.url}" +
                    " Elapsed time #{((end_time - start_time) * 1000.0).to_i}ms")
      headers["Date"] = end_time.rfc822 # As thin doesn't inject date

      @logger.debug("Sending response Status: #{status} Headers: #{headers} Body: #{body}")
      [ status, headers, body ]
    end

  end

end
