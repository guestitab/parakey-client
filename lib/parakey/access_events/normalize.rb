module Parakey
  module AccessEvents
    # Normalizes one event-log item or webhook delivery into the access event
    # attributes the host persists. The wire item is left untouched under
    # metadata[:payload].
    class Normalize
      include Parakey::Operation

      # Device maintenance activities report as a sync, not an unlock.
      SYNC_ACTIVITIES = %w[calibrate dfu setTime].freeze #: ::Array[::String]

      # @rbs (item: ::Hash[::Symbol, untyped]) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
      def call(item:)
        argument! item: :required if item.blank?

        Success(attributes(item))
      end

      private

      # @rbs (::Hash[::Symbol, untyped] item) -> ::Hash[::Symbol, untyped]
      def attributes(item)
        {
          external_id: item[:id],
          event_type: event_type(item),
          occurred_at: item[:timestamp].presence&.in_time_zone,
          grant_external_id: item.dig(:info, :accessKey, :id).presence,
          provider_lock_id: item.dig(:info, :device, :id).presence,
          access_id: item.dig(:info, :access, :id).presence,
          metadata: { payload: item }
        }
      end

      # @rbs (::Hash[::Symbol, untyped] item) -> ::String?
      def event_type(item)
        return 'synced' if SYNC_ACTIVITIES.include?(item[:activity])

        item[:activity].presence
      end
    end
  end
end
