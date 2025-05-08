# frozen_string_literal: true

# ruby -Itest test/test_ruby_lsp_hanami.rb
require "test_helper"

module RubyLsp
  module Hanami
    class TestDefinition < Minitest::Test
      include RubyLsp::TestHelper

      def test_my_addon_works
        source = <<~RUBY
          # Some test code that allows you to trigger your add-on's contribution
          class Create
          end
        RUBY

        p "starting ..."
        with_server(source) do |server, uri|
          p "with server #{uri}"
          # Tell the server to execute the definition request
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
          # Pop the server's response to the definition request
          # result = server.pop_response.response
          # p "result: #{result}"
          # # Assert that the response includes your add-on's contribution
          # assert_equal(123, result.response.location)
        end
      end
    end
  end
end
