require 'cgi'
require 'oauth2'

module LinkedIn2

  # The Weibo2::Client class
  class Client < OAuth2::Client
    include Helpers::Request
    include API::QueryMethods
    include API::UpdateMethods
    include Search

    attr_reader :redirect_uri
    attr_accessor :access_token
    
    # Initializes a new Client from a signed_request
    #
    # @param [String] code The Authorization Code value
    # @param [Hash] opts the options to create the client with
    # @option opts [Hash] :connection_opts ({}) Hash of connection options to pass to initialize Faraday with
    # @option opts [FixNum] :max_redirects (5) maximum number of redirects to follow
    # @yield [builder] The Faraday connection builder
    def self.from_code(code, opts={}, &block)
      client = self.new(opts, &block)
      client.auth_code.get_token(code)
      
      client
    end
    
    # Initializes a new Client from a signed_request
    #
    # @param [String] signed_request param posted by Sina
    # @param [Hash] opts the options to create the client with
    # @option opts [Hash] :connection_opts ({}) Hash of connection options to pass to initialize Faraday with
    # @option opts [FixNum] :max_redirects (5) maximum number of redirects to follow
    # @yield [builder] The Faraday connection builder
    def self.from_signed_request(signed_request, opts={}, &block)
      client = self.new(opts, &block)
      client.signed_request.get_token(signed_request)
      
      client
    end
    
    # Initializes a new Client from a hash
    #
    # @param [Hash] a Hash contains access_token and expires
    # @param [Hash] opts the options to create the client with
    # @option opts [Hash] :connection_opts ({}) Hash of connection options to pass to initialize Faraday with
    # @option opts [FixNum] :max_redirects (5) maximum number of redirects to follow
    # @yield [builder] The Faraday connection builder
    def self.from_hash(hash, opts={}, &block)
      client = self.new(opts, &block)
      client.get_token_from_hash(hash)
      
      client
    end

    # Initializes a new Client
    #
    # @param [Hash] opts the options to create the client with
    # @option opts [Hash] :connection_opts ({}) Hash of connection options to pass to initialize Faraday with
    # @option opts [FixNum] :max_redirects (5) maximum number of redirects to follow
    # @yield [builder] The Faraday connection builder 
    def initialize(opts={}, &block)
      id = LinkedIn2::Config.api_key
      secret = LinkedIn2::Config.api_secret
      @redirect_uri = LinkedIn2::Config.redirect_uri
      
      options = {:site          => "https://api.linkedin.com",
                 :authorize_url => "https://www.linkedin.com/uas/oauth2/authorization",
                 :token_url     => "https://www.linkedin.com/uas/oauth2/accessToken",
                 :raise_errors  => false,
                 :ssl           => {:verify => false}}.merge(opts)
          
      super(id, secret, options, &block)
    end
    
    # Whether or not the client is authorized
    #
    # @return [Boolean]
    def is_authorized?
      !!token && !token.expired?
    end

    # Initializes an AccessToken by making a request to the token endpoint
    #
    # @param [Hash] params a Hash of params for the token endpoint
    # @param [Hash] access token options, to pass to the AccessToken object
    # @return [AccessToken] the initalized AccessToken
    def get_token(params, access_token_opts={})
      params = params.merge(:parse => :json)
      access_token_opts = access_token_opts.merge({:mode => :query, :param_name => "oauth2_access_token"})
      
      @access_token = super(params, access_token_opts)
    end
    
    # Initializes an AccessToken from a hash
    #
    # @param [Hash] hash a Hash contains access_token and expires
    # @return [AccessToken] the initalized AccessToken
    def get_token_from_hash(hash)
      access_token = hash.delete('access_token') || hash.delete(:access_token) || hash.delete('oauth_token') || hash.delete(:oauth_token)
      opts = { :mode => :query, :param_name => "oauth2_access_token" }
      
      @access_token = OAuth2::AccessToken.new(self, access_token, opts)
    end
    
    # Refreshes the current Access Token
    #
    # @return [AccessToken] a new AccessToken
    # @note options should be carried over to the new AccessToken
    def refresh!(params={})
      @access_token = access_token.refresh!(params)
    end
   
    #
    # Strategies
    #
    
    # The Authorization Code strategy
    #
    # @see http://tools.ietf.org/html/draft-ietf-oauth-v2-15#section-4.1
    def auth_code
      @auth_code ||= LinkedIn2::Strategy::AuthCode.new(self)
    end
    
    # The Resource Owner Password Credentials strategy
    #
    # @see http://tools.ietf.org/html/draft-ietf-oauth-v2-15#section-4.3
    def password
      super
    end
    
    # The Signed Request Strategy
    #
    def signed_request
      @signed_request ||= LinkedIn2::Strategy::SignedRequest.new(self)
    end
    
  end
end
