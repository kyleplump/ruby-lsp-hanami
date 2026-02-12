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

      # def test_completion_candidates_found
      #   source = <<~RUBY
      #     module Fake
      #       class MyClass
      #         def my_method
      #         end
      #       end
      #     end
      #     # typed: false
      #     class MyOtherClass
      #       include Deps['fake.']
      #     end
      #   RUBY



      #   response = generate_completions_for_source(source, { line: 8, character: 23 })
      #   p "response: #{response}"

      #   assert response.any? { |item| item.is_a?(Interface::CompletionItem) }
      # end

      private

      def generate_completions_for_source(source, position)
        with_server(source) do |server, uri|
          server.process_message(
            id: 1,
            method: "textDocument/completion",
            params: {
              textDocument: { uri: uri },
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
