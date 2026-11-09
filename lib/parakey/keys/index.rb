module Parakey
  module Keys
    # Lists the domain's accesses (the reusable "keys" a grant points at),
    # restricted to API-enabled ones. Extra wire filters merge in verbatim, e.g.
    # { deviceIds: { in: [...] } }.
    class Index
      include Parakey::Operation

      ACCESS_FILTERS = {
        allowedOrigins: 'api',
        enabled: true
      }.freeze

      # @rbs (?skip: ::Integer, ?take: ::Integer, ?filters: ::Hash[::Symbol, untyped]) -> Dry::Monads::Result[::Array[::Hash[::Symbol, untyped]]]
      def call(skip: 0, take: 100, filters: {})
        params = ACCESS_FILTERS.merge(filters, page_params(skip, take))
        body = Parakey.request(:get, 'accesses', params:)

        Success(body.fetch(:items, []).map { |item| attributes(item) })
      end

      private

      # @rbs (::Hash[::Symbol, untyped] item) -> ::Hash[::Symbol, untyped]
      def attributes(item)
        {
          external_id: item[:id],
          name: item[:name].presence,
          device_ids: item.fetch(:devices, []).pluck(:id)
        }.compact
      end
    end
  end
end
