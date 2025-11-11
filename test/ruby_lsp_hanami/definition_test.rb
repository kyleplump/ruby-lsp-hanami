# frozen_string_literal: true

require_relative "../test_helper"

module RubyLsp
  module Hanami
    class DefinitionTest < Minitest::Test
      include RubyLsp::TestHelper

      # 'default_indexer' referring to RubyLsp's default index behavior (non-IndexEnhanced). this is base case
      def test_deps_default_indexer
        response = generate_definitions_for_source(<<~RUBY, { line: 6, character: 27 })
          # typed: false
          class MyClass
            def create; end
          end

          class MySecondClass
            include Deps['my_class.create']
          end
        RUBY

        assert_equal(1, response.size)
        assert_equal(2, response[0].range.start.line)
        assert_equal(2, response[0].range.start.character)
      end

      def test_deps_non_standard_definition
        # Operation#call methods are also valid injectable dependencies and are subject to definition requests. These dependencies are picked up
        # with the IndexingEnhancement, and set into the supplementary global store.  this is a good way to test 'non-default indexing behavior'
        response = generate_definitions_for_source(<<~RUBY, { line: 8, character: 25 })
          # typed: false
          module Fake
            class MyOperation < Hanami::Operation
              def call; end
            end
          end

          class MyClass
            include Deps['fake.my_operation']
          end
        RUBY

        # assert that one of the responses points to the call function
        assert response.any? do |resp|
          resp.range.start.line == 3 && resp.range.start.character == 4
        end
      end

      def generate_definitions_for_source(source, position)
        with_server(source) do |server, uri|
          server.process_message(
            id: 1,
            method: "textDocument/definition",
            params: { textDocument: { uri: uri }, position: position }
          )

          result = pop_result(server)
          result.response
        end
      end
    end
  end
end
