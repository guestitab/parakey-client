module Parakey
  module Members
    # Lists the domain's members, one page per call, items in the wire's own
    # shape (symbolized camelCase keys). Wire filters merge in verbatim, e.g.
    # { status: 'emailProblem' } for members whose invitation email bounced.
    class Index
      include Parakey::Operation

      # @rbs (?skip: ::Integer, ?take: ::Integer, ?filters: ::Hash[::Symbol, untyped]) -> Dry::Monads::Result[::Array[::Hash[::Symbol, untyped]]]
      def call(skip: 0, take: 100, filters: {})
        body = Parakey.request(:get, 'members', params: filters.merge(page_params(skip, take)))

        Success(body.fetch(:items, []))
      end
    end
  end
end
