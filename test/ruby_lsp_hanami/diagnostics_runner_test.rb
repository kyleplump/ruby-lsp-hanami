# frozen_string_literal: true

require_relative "../test_helper"

module RubyLsp
  module Hanami
    class DiagnosticsRunnerTest < Minitest::Test
      include RubyLsp::TestHelper

      def setup
        RubyLsp::Hanami.clear_entries
      end

      def test_no_deps_found
        source = <<~RUBY
          class MyClass
            def my_method; end
          end
        RUBY

        queue = run_diagnostics_for_source(source)
        assert_empty(queue)
      end

      def test_key_present
        source = <<~RUBY
          class MyOtherClass
            include Deps['fake.my_class']
          end

          module Fake
            class MyClass
            end
          end
        RUBY

        queue = run_diagnostics_for_source(source)
        refute_empty(queue)
        message = queue.pop
        assert_equal("textDocument/publishDiagnostics", message[:method])
        assert_empty(message[:params].diagnostics)
      end

      def test_key_not_found
        source = <<~RUBY
          class MyOtherClass
            include Deps['fake.my_class']
          end
        RUBY

        queue = run_diagnostics_for_source(source)
        refute_empty(queue)
        message = queue.pop
        assert_equal("textDocument/publishDiagnostics", message[:method])

        diagnostics = message[:params].diagnostics
        assert_equal(1, diagnostics.size)

        diagnostic = diagnostics.first
        assert_equal(1, diagnostic.severity) # 1 represents Error

        range = diagnostic.range
        assert_equal(1, range.start.line)
        assert_equal(1, range.end.line)
        assert(range.start.character > 0)
        assert(range.end.character > range.start.character)
      end

      private

      def run_diagnostics_for_source(source)
        with_server(source, URI("file://#{Dir.pwd}/fake.rb")) do |server, uri|
          message_queue = Thread::Queue.new
          runner = HanamiDiagnosticsRunner.new(message_queue, server.global_state.index)
          document = RubyLsp::RubyDocument.new(
            source: source,
            version: 1,
            uri: uri,
            global_state: server.global_state
          )

          runner.run_diagnostic(uri, document)
          message_queue
        end
      end
    end
  end
end
