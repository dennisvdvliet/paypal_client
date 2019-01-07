# frozen_string_literal: true

require 'faraday_middleware'

module PaypalClient
  module Errors
    class Error < StandardError
      attr_reader :code
      attr_reader :http_body
      attr_reader :http_status
      attr_reader :error_message

      def initialize(error_message = nil, http_status: nil, http_body: nil, code: nil)
        @error_message = error_message
        @http_status = http_status
        @http_body = http_body
        @code = code

        super(@error)
      end

      def inspect
        extra = []
        extra << " status_code: #{http_status}" unless http_status.nil?
        extra << " body: #{http_body}" unless http_body.nil?
        "#<#{self.class.name}: #{message}#{extra.join}>"
      end

      def message
        "#{code}: #{error_message} (#{http_status})"
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

      ERRORS_WITHOUT_BODY = [404].freeze

      def on_complete(response)
        status = response[:status].to_i
        if status >= 400
          error = ERROR_MAP.key?(status) ? ERROR_MAP[status] : Error

          body = response.body
          raise error.new(get_error_message(response), code: get_error_code(response), http_status: status, http_body: body)
        end
      end

      private

      def get_error_message(response)
        body = response.body
        return body[:message] if body.is_a?(Hash) && body.key?(:message)
        return body[:error_description] if body.is_a?(Hash) && body.key?(:error_description)

        'Something went wrong'
      end

      def get_error_code(response)
        body = response.body
        return body[:name] if body.is_a?(Hash) && body.key?(:name)
        return body[:error] if body.is_a?(Hash) && body.key?(:error)

        response.status.to_s
      end
    end
  end
end
