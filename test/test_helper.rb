# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ruby_lsp_hanami"

require "minitest/autorun"
require "ruby_lsp/internal"
require "ruby_lsp/test_helper"
require "ruby_lsp/ruby_lsp_hanami/addon"

module ActiveSupport
  class TestCase
    extend T::Sig
    include RubyLsp::TestHelper
  end
end