module Parakey
  # The normalized vocabulary the access-key operations return. Parakey access
  # keys come in two kinds: a permanent key (regular) and a time-windowed key
  # (time-controlled access, tca); a key is active while enabled.
  module AccessGrants
    KIND_REGULAR = 'regular'.freeze
    KIND_TIME_CONTROLLED = 'tca'.freeze
    KINDS = [KIND_REGULAR, KIND_TIME_CONTROLLED].freeze #: ::Array[::String]

    STATUS_ACTIVE = 'active'.freeze
    STATUS_INACTIVE = 'inactive'.freeze
  end
end
