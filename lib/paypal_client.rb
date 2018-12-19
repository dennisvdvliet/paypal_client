# frozen_string_literal: true

require 'paypal_client/version'
require 'active_support/cache'

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

    def self.build
      @client ||= Client.new(
        client_id: ENV.fetch('PAYPAL_CLIENT_ID'),
        client_secret: ENV.fetch('PAYPAL_CLIENT_SECRET'),
        sandbox: ENV.fetch('PAYPAL_SANDBOX', true),
        cache: ActiveSupport::Cache::MemoryStore.new,
        version: VERSION
      )
    end

    def initialize(client_id:, client_secret:, cache:, sandbox: true, version:, logger: nil)
      @client_id = client_id
      @client_secret = client_secret
      @cache = cache
      @sandbox = sandbox
      @version = version
      @logger = logger
    end

    def connection
      @conn ||= Faraday.new(url: base_url) do |faraday|
        faraday.headers = default_headers
        faraday.response @logger if @logger
        faraday.request  :json
        faraday.response :json, parser_options: { symbolize_names: true }

        faraday.use ErrorMiddleware
        faraday.adapter *adapter
      end
    end

    %i[get patch post put delete].each do |http_method|
      define_method http_method do |path, data = {}, headers = {}|
        connection.public_send(http_method, merged_path(path), data, merged_headers(headers))
      end
    end

    def auth_token(force: false)
      return @cache.read(TOKEN_CACHE_KEY) if @cache.exist?(TOKEN_CACHE_KEY) && force == false

      auth_response = authenticate
      @cache.fetch(TOKEN_CACHE_KEY, expires_in: auth_response[:expires_in] - TOKEN_EXPIRY_MARGIN) do
        auth_response[:access_token]
      end
    end

    private

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

  class ResponseError < StandardError; end
  class NotFound < ResponseError; end

  class ErrorMiddleware < Faraday::Response::Middleware
    ERROR_MAP = {
      404 => NotFound
    }.freeze

    def on_complete(response)
      key = response[:status].to_i
      raise ERROR_MAP[key], response if ERROR_MAP.key? key
      raise ResponseError, response if response.status >= 400
    end
  end
end
