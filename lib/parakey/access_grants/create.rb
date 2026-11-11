module Parakey
  module AccessGrants
    # Creates an access key: permanent for a regular grant, time-windowed for a
    # time-controlled one. Parakey upserts by access, user and window, so a repeat
    # of an identical grant resolves to the existing key instead of duplicating it.
    class Create
      include Parakey::Operation

      # @rbs (attributes: ::Hash[::Symbol, untyped]) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
      def call(attributes:)
        argument! 'Access ID is required.' if attributes[:access_id].blank?
        argument! 'Grant kind is invalid.' unless KINDS.include?(attributes[:kind])
        argument! 'Recipient email is required.' if attributes[:recipient_email].blank?

        validate_validity_window!(attributes)

        body = Parakey.request(:post, 'access-keys', params: payload(attributes))

        Success(external_id: body.fetch(:id), metadata: { raw: body })
      end

      private

      # A regular grant never carries a window; a time-controlled one always
      # does, ending after it starts.
      # @rbs (::Hash[::Symbol, untyped] attributes) -> void
      def validate_validity_window!(attributes)
        if attributes[:kind] == KIND_TIME_CONTROLLED
          argument! 'Start date and end date are both required.' if attributes[:start_date].blank? || attributes[:end_date].blank?
          argument! 'End date must be after start date.' if attributes[:start_date].in_time_zone >= attributes[:end_date].in_time_zone
        elsif attributes[:start_date].present? || attributes[:end_date].present?
          argument! 'A validity window is only supported for time-controlled grants.'
        end
      end

      # @rbs (::Hash[::Symbol, untyped] attributes) -> ::Hash[::Symbol, untyped]
      def payload(attributes)
        {
          access: { id: attributes[:access_id] },
          user: { email: attributes[:recipient_email] },
          startDate: attributes[:start_date]&.iso8601,
          expirationDate: attributes[:end_date]&.iso8601
        }.compact
      end
    end
  end
end
