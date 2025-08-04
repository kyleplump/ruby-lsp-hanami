# typed: true

module RubyLsp
  module Hanami
    extend T::Sig
    @container_keys = {}

    def self.container_keys
      @container_keys
    end

    # TODO: fix this
    sig { params(key: String, value: T.anything).void }
    def self.set_container_key(key, value)
      # convert key to downcase snake case
      # taken from: https://gist.github.com/cjmeyer/4268723
      formatted_key = key.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                         .gsub(/([a-z])([A-Z])/, '\1_\2')
                         .downcase

      @container_keys[formatted_key] = value
    end
  end
end
