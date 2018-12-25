# frozen_string_literal: true

require 'paypal_client/version'
require 'paypal_client/errors'
require 'active_support/cache'

#
# Module PaypalClient provides an easy to use API client for the Paypal
# REST API https://developer.paypal.com/docs/api/overview/
#
# @author Dennis van der Vliet <dennis.vandervliet@gmail.com>
#
module PaypalClient
  require 'faraday'
  require 'faraday_middleware'

  class Client
    LIVE_URL = 'https://api.paypal.com'.freeze
    SANDBOX_URL = 'https://api.sandbox.paypal.com'.freeze
    VERSION = 'v1'.freeze

    TOKEN_CACHE_KEY = 'paypal_oauth_token'.freeze
    # We don't want to use a token that expired 1 second ago
    # so we have them expiry 3600 seconds before they actually expire
    TOKEN_EXPIRY_MARGIN = 60 * 60

    # Build a new instance of PaypalClient based on defaults and environment
    # variables
    # @return [PaypalClient::Client] an instance of PaypalClient::Client
    def self.build
      @client ||= Client.new(
        client_id: ENV.fetch('PAYPAL_CLIENT_ID'),
        client_secret: ENV.fetch('PAYPAL_CLIENT_SECRET'),
        sandbox: ENV.fetch('PAYPAL_SANDBOX', true),
        cache: ActiveSupport::Cache::MemoryStore.new,
        version: VERSION
      )
    end

    # Creates a new instance of PaypalClient::Client
    #
    # @param [String] client_id: Paypal Client ID
    # @param [String] client_secret: Paypal Client Secret
    # @param [ActiveSupport::Cache::Store] cache: ActiveSupport::Cache::Store compaitable store to store auth token
    # @param [Boolean] sandbox: true <description>
    # @param [String] version: <description>
    # @param [Logger] logger: nil <description>
    
    def initialize(client_id:, client_secret:, cache:, sandbox: true, version:, logger: nil)
      @client_id = client_id
      @client_secret = client_secret
      @cache = cache
      @sandbox = sandbox
      @version = version
      @logger = logger
    end

    # Send a GET request to the Paypal API
    #
    # @param [String] path Path to call on Paypal API (eg. /payments/payment)
    # @param [Hash] data Hash to send as query parameters
    # @param [Hash] headers Hash of custom request headers
    #
    # @return [Faraday::Response>] Faraday response. Call the `.body` method on it to access the response data.
    
    def get(path, data = {}, headers = {})
      connection.get(merged_path(path), data, merged_headers(headers))
    end

    # Send a POST request to the Paypal API
    #
    # @param [String] path Path to call on Paypal API (eg. /payments/payment)
    # @param [Hash] data Hash to send as POST data. Will be turned into JSON.
    # @param [Hash] headers Hash of custom request headers
    #
    # @return [Faraday::Response>] Faraday response. Call the `.body` method on it to access the response data.
    
    def post(path, data = {}, headers = {})
      connection.post(merged_path(path), data, merged_headers(headers))
    end

    # Send a PUT request to the Paypal API
    #
    # @param [String] path Path to call on Paypal API (eg. /payments/payment)
    # @param [Hash] data Hash to send as POST data. Will be turned into JSON.
    # @param [Hash] headers Hash of custom request headers
    #
    # @return [Faraday::Response>] Faraday response. Call the `.body` method on it to access the response data.
    
    def put(path, data = {}, headers = {})
      connection.public_send(:get, merged_path(path), data, merged_headers(headers))
    end

    # Send a PATCH request to the Paypal API
    #
    # @param [String] path Path to call on Paypal API (eg. /payments/payment)
    # @param [Hash] data Hash to send as POST data. Will be turned into JSON.
    # @param [Hash] headers Hash of custom request headers
    #
    # @return [Faraday::Response>] Faraday response. Call the `.body` method on it to access the response data.

    def patch(path, data = {}, headers = {})
      connection.patch(merged_path(path), data, merged_headers(headers))
    end

    # Send a DELETE request to the Paypal API
    #
    # @param [String] path Path to call on Paypal API (eg. /payments/payment)
    # @param [Hash] data Hash to send as POST data. Will be turned into JSON.
    # @param [Hash] headers Hash of custom request headers
    #
    # @return [Faraday::Response>] Faraday response. Call the `.body` method on it to access the response data.

    def delete(path, data = {}, headers = {})
      connection.delete(merged_path(path), data, merged_headers(headers))
    end

    # Request auth token from Paypal using the client_id and client_secret
    #
    # @param [<Boolean>] force: false Forces a refresh of the token even if cached
    #
    # @return [<String>] Valid auth token from Paypal
    # 
    def auth_token(force: false)
      return @cache.read(TOKEN_CACHE_KEY) if @cache.exist?(TOKEN_CACHE_KEY) && force == false

      auth_response = authenticate
      @cache.fetch(TOKEN_CACHE_KEY, expires_in: auth_response[:expires_in] - TOKEN_EXPIRY_MARGIN) do
        auth_response[:access_token]
      end
    end

    private

    def connection
      @conn ||= Faraday.new(url: base_url) do |faraday|
        faraday.use PaypalClient::Errors::Middleware

        faraday.headers = default_headers
        faraday.response @logger if @logger
        faraday.request  :json
        faraday.response :json, content_type: /\bjson$/, parser_options: { symbolize_names: true }

        faraday.adapter *adapter
      end
    end

    def base_url
      @sandbox ? SANDBOX_URL : LIVE_URL
    end

    def merged_headers(headers)
      headers.merge(auth_header).merge(default_headers)
    end

    def merged_path(path)
      File.join(@version, path).gsub(File::SEPARATOR, '/')
    end

    def auth_header
      { authorization: "Bearer #{auth_token}" }
    end

    def default_headers
      {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }
    end

    def authenticate
      basic_auth = ["#{@client_id}:#{@client_secret}"].pack('m').delete("\r\n")
      endpoint = [@version, 'oauth2', 'token'].join('/')

      response = connection.post(endpoint,
                                 'grant_type=client_credentials',
                                 authorization: "Basic #{basic_auth}", "Content-Type": 'application/x-www-form-urlencoded')
      response.body
    end

    def adapter
      Faraday.default_adapter
    end
  end
end
