# frozen_string_literal: true

require 'multi_json'
require 'dry-validation'

module JsonRPC
  class RequestSchema < Dry::Validation::Contract
    params do
      required(:jsonrpc).filled(:str?, eql?: '2.0')
      required(:method).filled(:str?)
      optional(:params) { type?(Array) | type?(Hash) }
      optional(:id) { none? | type?(String) | type?(Integer) }
    end
  end
  class Parser
    def parse(request_body)
      parsed = parse_json(request_body)

      if batch_request?(parsed)
        parsed.map { |current| create_request(current) }
      else
        create_request(parsed)
      end
    end

    private

    def parse_json(request_body)
      MultiJson.load(request_body, symbolize_keys: true)
    rescue MultiJson::ParseError
      raise InvalidJSONError
    end

    def batch_request?(parsed)
      parsed.is_a?(Array)
    end

    def validate(parsed)
      validation = JsonRPC::RequestSchema.new.call(parsed)
      validated = validation.to_h
      validated[:invalid] = validation.failure?
      validated
    end

    def create_request(parsed)
      Request.new(validate(parsed))
    end
  end
end
