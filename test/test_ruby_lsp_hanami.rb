# frozen_string_literal: true

# ruby -Itest test/test_ruby_lsp_hanami.rb
#
# this doesnt really work yet
require "test_helper"

module RubyLsp
  module Hanami
    class TestDefinition < Minitest::Test
      include RubyLsp::TestHelper

      def test_my_addon_works
        source = <<~RUBY
          class Create
          end
        RUBY

        with_server(source) do |server, uri|
          server.process_message(
            id: 1,
            method: "textDocument/definition",
            params: {
              textDocument: {
                uri: uri.to_s
              },
              position: {
                line: 1,
                character: 7
              }
            }
          )

          result = pop_result(server)
          p "result: #{result.response}"
        end
      end
    end
  end
end
