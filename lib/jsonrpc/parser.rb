require 'multi_json'
require 'dry-validation'

module JsonRPC
  class Parser
    def parse(request_body)
      parsed = MultiJson.load(request_body, symbolize_keys: true)

      if batch_request?(parsed)
        parsed.map { |current| build_request(current) }
      else
        build_request(parsed)
      end
    rescue MultiJson::ParseError
      raise InvalidJSONError
    end

    private

    def batch_request?(parsed)
      parsed.is_a?(Array)
    end

    def build_request(parsed)
      validation = RequestSchema.call(parsed)
      if validation.failure?
        raise InvalidRequestError
      end

      Request.new(validation.to_h)
    end
  end

  private

  RequestSchema = Dry::Validation.Schema do
    required(:jsonrpc).filled(:str?, eql?: "2.0")
    required(:method).filled(:str?)
    optional(:params) { type?(Array) | type?(Hash) }
    optional(:id) { none? | type?(String) | type?(Integer) }
  end
end
