# frozen_string_literal: true

# ruby -Itest test/test_ruby_lsp_hanami.rb
#
# this doesnt really work yet
require "test_helper"

module RubyLsp
  module Hanami
    class DefinitionTest < Minitest::Test
      include RubyLsp::TestHelper

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

      def test_deps_indexing_enhancement_operation_call
        # Operation#call methods are also valid injectable dependencies and are subject to definition requests. These dependencies are picked up
        # with the IndexingEnhancement, and set into the global hash for lookup.  mock this behavior
        #
        # a foot gun: this function automatically decrements line numbers by one based on difference between the indexer being 1 based
        # and LSP protocol being 0 based
        # https://github.com/Shopify/ruby-lsp/blob/af955d8d2291f20147375c117cdd1efb1c37905d/lib/ruby_lsp/requests/support/common.rb#L27
        #
        # have the line starts be +1
        operation_call_def_location = Struct.new(:start_line, :start_column, :end_line, :end_column).new(4, 4, 4, 8)
        definition_entry = Struct.new(:location, :file_path).new(operation_call_def_location, '/fake/my_operation.rb')
        RubyLsp::Hanami.set_container_key('fake.my_operation', definition_entry)

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

        assert_equal(1, response.size)
        assert_equal(3, response[0].range.start.line)
        assert_equal(4, response[0].range.start.character)
        assert_equal(3, response[0].range.end.line)
        assert_equal(8, response[0].range.end.character)
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
