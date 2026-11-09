module Parakey
  module AccessGrants
    # Deletes an access key. A key that is already gone answers 404, which reads
    # as success: the desired end state is reached either way.
    class Delete
      include Parakey::Operation

      # @rbs (attributes: ::Hash[::Symbol, untyped]) -> Dry::Monads::Result[bool]
      def call(attributes:)
        argument! external_id: :required if attributes[:external_id].blank?

        path = "access-keys/#{ERB::Util.url_encode(attributes[:external_id])}"
        Parakey.request(:delete, path, accepted_statuses: [404])

        Success(true)
      end
    end
  end
end
