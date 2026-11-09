module Parakey
  module Locks
    # Lists the domain's devices, each with the accesses that reach it. One page
    # of devices per call; the accesses join pages through Keys::Index on its own.
    class Index
      include Parakey::Operation

      BATTERY_CHARGES = {
        'high' => 100,
        'medium' => 75,
        'low' => 50,
        'veryLow' => 25
      }.freeze #: ::Hash[::String, ::Integer]

      ACCESS_BATCH_SIZE = 500

      # The wire reports no device status; a device the API lists reads as online.
      STATUS_ONLINE = 'online'.freeze

      # @rbs (?skip: ::Integer, ?take: ::Integer) -> Dry::Monads::Result[::Array[::Hash[::Symbol, untyped]]]
      def call(skip: 0, take: 100)
        devices = Parakey.request(:get, 'devices', params: page_params(skip, take)).fetch(:items, [])
        accesses = accesses(devices.pluck(:id))

        Success(devices.map { |device| attributes(device, accesses) })
      end

      private

      # @rbs (::Array[::String] device_ids) -> ::Array[::Hash[::Symbol, untyped]]
      def accesses(device_ids)
        return [] if device_ids.empty?

        filters = { deviceIds: { in: device_ids } }
        result = []

        loop do
          page = Parakey::Keys::Index.new.call!(skip: result.size, take: ACCESS_BATCH_SIZE, filters:).value!
          result.concat(page)
          break if page.size < ACCESS_BATCH_SIZE
        end

        result
      end

      # @rbs (::Hash[::Symbol, untyped] device, ::Array[::Hash[::Symbol, untyped]] accesses) -> ::Hash[::Symbol, untyped]
      def attributes(device, accesses)
        reaching = accesses.select { |access| access[:device_ids].include?(device[:id]) }

        {
          external_id: device[:id],
          name: device[:name],
          status: STATUS_ONLINE,
          charge: BATTERY_CHARGES[device[:batteryStatus]],
          keys: reaching.map { |access| access.slice(:external_id, :name) }
        }
      end
    end
  end
end
