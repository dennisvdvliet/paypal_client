require 'faraday_middleware'

module PaypalClient
  module Errors
    class Error < StandardError
      attr_reader :status_code
      attr_reader :body
      attr_reader :error
      attr_reader :error_message

      def initialize(response)
        @status_code = response.status
        @body = response.body

        @error = @body[:name] if @body.has_key?(:name)
        @error_message = @body[:message] if @body.has_key?(:message)
      end

      def to_s

      end
    end

    class InvalidRequest < Error; end
    class AuthenticationFailure < Error; end
    class NotAuthorized < Error; end
    class ResourceNotFound < Error; end
    class MethodNotSupported < Error; end
    class MediaTypeNotAcceptable < Error; end
    class UnsupportedMediaType < Error; end
    class UnprocessableEntity < Error; end
    class RateLimitReached < Error; end
    
    class InternalServerError < Error; end
    class ServiceUnavailable < Error; end

    class Middleware < ::Faraday::Response::Middleware
      ERROR_MAP = {
        400 => InvalidRequest,
        401 => AuthenticationFailure,
        403 => NotAuthorized,
        404 => ResourceNotFound,
        405 => MethodNotSupported,
        406 => MediaTypeNotAcceptable,
        415 => UnsupportedMediaType,
        422 => UnprocessableEntity,
        429 => RateLimitReached,
        500 => InternalServerError,
        503 => ServiceUnavailable
      }.freeze

      def on_complete(response)
        key = response[:status].to_i
        raise ERROR_MAP[key], response if ERROR_MAP.key? key
        raise Error, response if response.status >= 400
      end
    end
  end
end
