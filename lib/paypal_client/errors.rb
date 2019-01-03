# frozen_string_literal: true

require 'faraday_middleware'

module PaypalClient
  module Errors
    class Error < StandardError
      attr_reader :code
      attr_reader :http_body
      attr_reader :http_status
      attr_reader :message

      def initialize(message = nil, http_status: nil, http_body: nil, code: nil)
        @message = message
        @http_status = http_status
        @http_body = http_body
        @code = code

        super(@error)
      end

      def inspect
        extra = ''
        extra << " status_code: #{http_status.inspect}" unless http_status.nil?
        extra << " body: #{http_body.inspect}" unless http_body.nil?
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
        status = response[:status].to_i
        if status >= 400
          error = ERROR_MAP.key?(status) ? ERROR_MAP[status] : Error

          body = response.body
          if body.class != Hash
            error = Error.new('Something went wrong', http_status: status, http_body: body)
          else
            error = error.new(body[:message], code: body[:name], http_status: status, http_body: body)
          end
          raise error
        end
      end
    end
  end
end
