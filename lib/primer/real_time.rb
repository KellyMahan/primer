module Primer
  class RealTime < Faye::RackAdapter
    
    BAYEUX_CONFIG = {:mount => '/primer/bayeux', :timeout => 25}
    SCRIPT_PATH   = '/primer.js'
    TYPE_SCRIPT   = {'Content-Type' => 'text/javascript'}
    SCRIPT_SOURCE = File.read(ROOT + '/javascript/primer.js')
    
    autoload :PublishRestriction,   ROOT + '/primer/real_time/publish_restriction'
    autoload :ClientAuthentication, ROOT + '/primer/real_time/client_authentication'
    
    def initialize(app)
      super(app, BAYEUX_CONFIG)
      add_extension(PublishRestriction.new)
    end
    
    def call(env)
      request = Rack::Request.new(env)
      return super unless request.path_info == SCRIPT_PATH
      [200, TYPE_SCRIPT, [SCRIPT_SOURCE]]
    end
    
    class << self
      attr_accessor :bayeux_server, :password
      
      def dom_id(cache_key)
        "primer#{ ('-' + cache_key).gsub(/[^a-z0-9]+/i, '-') }"
      end
      
      def publish(cache_key, value)
        return unless Primer.real_time
        client.publish(cache_key,
          :dom_id  => dom_id(cache_key),
          :content => value
        )
      end
      
    private
      
      def client
        raise NotConfigured.new unless bayeux_server
        
        Faye.ensure_reactor_running!
        return @client if @client
        
        endpoint = "#{ bayeux_server }#{ BAYEUX_CONFIG[:mount] }"
        @client = Faye::Client.new(endpoint)
        @client.add_extension(ClientAuthentication.new)
        
        @client
      end
    end
    
  end
end

