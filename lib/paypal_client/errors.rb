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

        if @body.class == Hash
          @error = @body[:name] if @body.key?(:name)
          @error_message = @body[:message] if @body.key?(:message)
        else
          @error = response.reason_phrase if @error.nil?
        end
        super(@error)
      end

      def inspect
        extra = ''
        extra << " status_code: #{status_code.inspect}" unless status_code.nil?
        extra << " body: #{body.inspect}"               unless body.nil?
        "#<#{self.class.name}: #{message}#{extra}>"
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
