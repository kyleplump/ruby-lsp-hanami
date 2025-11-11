# frozen_string_literal: true

require_relative "../test_helper"

module RubyLsp
  module Hanami
    class IndexingEnhancementTest < Minitest::Test
      include RubyLsp::TestHelper

      def setup
        RubyLsp::Hanami.clear_entries
      end

      def test_discovers_class_nodes
        source = <<~RUBY
          # typed: false
          module Fake
            class MyClass
              def call; end
            end
          end
        RUBY

        with_server(source) do |_server, _uri|
          assert_equal(true, RubyLsp::Hanami.container_key?(key: 'fake.my_class'))
        end
      end

      # sort of covered by DefinitionTest#test_deps_non_standard_definition,
      # this test is complimentary to that one
      # def test_discovers_operation_call_functions
      #   source = <<~RUBY
      #     # typed: false
      #     module Fake
      #       class MyOperation < Hanami::Operation
      #         def call; end
      #       end
      #     end
      #   RUBY

      #   with_server(source) do |_server, _uri|
      #     assert_equal(true, RubyLsp::Hanami.container_key?(key: 'fake.my_operation'))
      #     assert_equal(2, RubyLsp::Hanami.get_entries(key: 'fake.my_operation'))
      #   end
      # end
    end
  end
end
