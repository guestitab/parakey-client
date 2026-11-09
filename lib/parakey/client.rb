module Parakey
  BASE_URL = 'https://api.parakey.co/'.freeze #: ::String

  # Access-key POSTs create grants without a provider idempotency key, so a write
  # never retries; reads retry on a status or a connection-level failure.
  RETRY_OPTIONS = {
    max: 3,
    interval: 0.5,
    interval_randomness: 0.5,
    backoff_factor: 2,
    retry_statuses: [429, 502, 503, 504],
    methods: %i[get delete],
    exceptions: [*Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS, Faraday::ConnectionFailed, Faraday::SSLError]
  }.freeze #: ::Hash[::Symbol, untyped]

  # @rbs () -> Faraday::Connection
  def self.connection
    @connection ||= Faraday.new(url: config.base_url) do |builder|
      builder.request :json
      builder.request :retry, RETRY_OPTIONS
      builder.response :json, parser_options: { symbolize_names: true, mode: :rails, decoder: [Oj, :load] }
      builder.options[:timeout] = config.timeout
    end
  end

  # @rbs (::Symbol method, ::String path, ?params: ::Hash[::Symbol, untyped]?, ?accepted_statuses: ::Array[::Integer]) -> untyped
  def self.request(method, path, params: nil, accepted_statuses: [])
    response = connection.public_send(method, path, params, auth_headers)

    return response.body if response.success? || accepted_statuses.include?(response.status)

    raise ApiError.new(error_message(response), status: response.status)
  end

  # @rbs () -> ::Hash[::String, ::String]
  private_class_method def self.auth_headers
    access_token = config.access_token.presence || raise(Error, 'Parakey access token is required.')

    { 'Access-Token' => access_token }
  end

  # @rbs (Faraday::Response response) -> ::String
  private_class_method def self.error_message(response)
    body = response.body
    message = body.is_a?(Hash) ? body[:message] : nil

    message.presence || body.to_s.presence || "Provider request failed with status #{response.status}"
  end
end
