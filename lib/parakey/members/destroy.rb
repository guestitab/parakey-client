module Parakey
  module Members
    # Removes a domain member by email. An unknown member answers 404, which
    # reads as success: the member is gone either way.
    class Destroy
      include Parakey::Operation

      # @rbs (email: ::String?) -> Dry::Monads::Result[bool]
      def call(email:)
        argument! email: :required if email.blank?
        argument! domain_id: :required if Parakey.config.domain_id.blank?

        filter = {
          domainId: Parakey.config.domain_id,
          email:
        }
        Parakey.request(:post, 'members/delete', params: { filter: }, accepted_statuses: [404])

        Success(true)
      end
    end
  end
end
