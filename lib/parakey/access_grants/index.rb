module Parakey
  module AccessGrants
    # Lists the domain's access keys, one page per call.
    class Index
      include Parakey::Operation

      # @rbs (?skip: ::Integer, ?take: ::Integer) -> Dry::Monads::Result[::Array[::Hash[::Symbol, untyped]]]
      def call(skip: 0, take: 100)
        body = Parakey.request(:get, 'access-keys', params: page_params(skip, take))

        Success(body.fetch(:items, []).map { |item| attributes(item) })
      end

      private

      # @rbs (::Hash[::Symbol, untyped] item) -> ::Hash[::Symbol, untyped]
      def attributes(item)
        user = item[:user] || {}

        {
          external_id: item[:id],
          label: item[:aliasTag],
          recipient_email: user[:email],
          recipient_name: user[:name],
          status: item[:enabled] ? STATUS_ACTIVE : STATUS_INACTIVE,
          kind: grant_kind(item),
          access_id: item.dig(:access, :id),
          start_date: item[:startDate],
          end_date: item[:expirationDate]
        }
      end

      # A key with both dates is time-controlled; anything else is permanent.
      # @rbs (::Hash[::Symbol, untyped] item) -> ::String
      def grant_kind(item)
        return KIND_TIME_CONTROLLED if item[:startDate].present? && item[:expirationDate].present?

        KIND_REGULAR
      end
    end
  end
end
