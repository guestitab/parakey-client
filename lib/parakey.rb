require 'active_support'
require 'active_support/core_ext'
require 'dry/monads'
require 'erb'
require 'faraday'
require 'faraday/retry'
require 'oj'

require_relative 'parakey/version'
require_relative 'parakey/error'
require_relative 'parakey/api_error'
require_relative 'parakey/config'
require_relative 'parakey/operation'
require_relative 'parakey/client'
require_relative 'parakey/access_grants'
require_relative 'parakey/access_events/normalize'
require_relative 'parakey/access_grants/create'
require_relative 'parakey/access_grants/delete'
require_relative 'parakey/access_grants/index'
require_relative 'parakey/keys/index'
require_relative 'parakey/locks/index'
require_relative 'parakey/members/destroy'
require_relative 'parakey/members/index'

module Parakey
  class << self
    # @rbs () { (Config) -> void } -> void
    def configure
      yield(config)
    end

    # @rbs () -> Config
    def config
      @config ||= Config.new
    end
  end
end
