module Parakey
  # Shared monadic contract for the client operations: #call returns a Result,
  # #call! unwraps it and raises the underlying failure. An error raised inside
  # #call becomes Failure(error), mirroring the host's operation base.
  module Operation
    def self.included(base)
      base.include Dry::Monads[:result]
      base.prepend(Call)
    end

    module Call
      def call(*, **, &)
        super
      rescue StandardError => e
        Failure(e)
      end
    end

    def call!(...)
      result = call(...)
      raise result.failure if result.failure?

      result
    end

    private

    def argument!(message)
      raise Parakey::ArgumentError, message
    end

    # Lists page 1-based by page and limit on the wire; the operations take an item offset.
    # @rbs (::Integer skip, ::Integer take) -> ::Hash[::Symbol, untyped]
    def page_params(skip, take)
      argument! 'Take must be a positive number.' unless take.to_i.positive?

      {
        domainId: Parakey.config.domain_id,
        limit: take,
        page: skip.div(take) + 1
      }
    end
  end
end
