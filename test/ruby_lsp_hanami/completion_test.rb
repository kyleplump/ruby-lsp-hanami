# frozen_string_literal: true

require_relative "../test_helper"

module RubyLsp
  module Hanami
    class CompletionTest < Minitest::Test
      include RubyLsp::TestHelper

      def test_completion_with_non_supported_container
        source = <<~RUBY
          # typed: false
          class MyClass
            include Test['my_class']
          end
        RUBY

        response = generate_completions_for_source(source, { line: 2, character: 23 })
        assert response.empty?
      end

      def test_completion_candidates_not_found
        source = <<~RUBY
          # typed: false
          class MyClass
            include Deps['my_class']
          end
        RUBY

        response = generate_completions_for_source(source, { line: 2, character: 23 })
        assert response.empty?
      end

      def test_completion_candidates_found
        source = <<~RUBY
          module Fake
            class MyClass
              def my_method
              end
            end
          end
          # typed: false
          class MyOtherClass
            include Deps['fake.']
          end
        RUBY

        response = generate_completions_for_source(source, { line: 8, character: 21 })

        assert(response.any? { |item| item.is_a?(Interface::CompletionItem) })
      end

      private

      def generate_completions_for_source(source, position)
        # use a hard-coded fake URI within our current working directory, since the
        # IndexingEnhancement will disregard files outside of the working directory.
        with_server(source, URI("file://#{Dir.pwd}/fake.rb")) do |server, parsed_uri|
          server.process_message(
            id: 1,
            method: "textDocument/completion",
            params: {
              textDocument: { uri: parsed_uri },
              position: position
            }
          )

          result = pop_result(server)
          result.response || []
        end
      end
    end
  end
end
