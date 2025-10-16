# typed: true
# frozen_string_literal: true

module RubyLsp
  # top level comment
  #
  module Hanami
    extend T::Sig
    @container_keys = {}
    # dumb
    CONTAINERS = %w[deps app].freeze

    def self.container_keys
      @container_keys
    end

    # TODO: update sig to not use anything
    sig { params(key: String, value: T.anything).void }
    def self.set_container_key(key, value)
      # convert key to downcase snake case
      # taken from: https://gist.github.com/cjmeyer/4268723
      formatted_key = key.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                         .gsub(/([a-z])([A-Z])/, '\1_\2')
                         .downcase

      @container_keys[formatted_key] = value
    end

    def self.find_index_entries(key:, index: nil)
      # first look for potentially matching keys picked up during indexing
      # look in both directions. for the case where the cached key is a substring or exact match of the node content
      # -> e.g.: cached key is "repos.my_repo" and the node content is "repos.my_repo"
      # as well as when the node content is longer than the cached key (this could happen with Slice imports)
      # -> e.g.: cached key is "repos.my_repo" and the node content is "main_slice.repos.job_repo" (in the case that the Definition
      # request comes from a slice)
      matched = @container_keys.select do |k, _|
        k.include?(key) || key.include?(k)
      end.values || []

      unless index.nil?
        matched += index.resolve(key.split(".").last,
                                       key.split(".")[0, key.split(".").length - 1]) || []

      end

      matched.uniq!
      matched
    end
  end
end
