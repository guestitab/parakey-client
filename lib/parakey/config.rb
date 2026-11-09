module Parakey
  # Injected by the host app (see the Parakey.configure initializer): the static
  # API access token and the domain every call scopes to. Keeping these out of
  # the gem is what makes it host-agnostic.
  #
  # Parakey issues one long-lived access token per account (no OAuth minting), so
  # there is no token store to inject; the host reads the token from its own
  # credentials and hands it over here.
  class Config
    attr_accessor :access_token, :domain_id, :base_url, :timeout

    def initialize
      @base_url = BASE_URL
    end
  end
end
