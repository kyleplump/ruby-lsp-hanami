# typed: true
# frozen_string_literal: true

module RubyLsp
  module Hanami
    class HanamiDiagnosticsRunner
      include RubyLsp::Requests::Support::Formatter

      def initialize(message_queue)
        @message_queue = message_queue
      end

      def run_formatting(uri, document)
        run_diagnostic(uri, document)
        document.source
      end

      def run_diagnostic(uri, document)
        diagnostic = RubyLsp::Interface::Diagnostic.new(
          message: "test diagnostic",
          range: RubyLsp::Interface::Range.new(
            start: RubyLsp::Interface::Position.new(line: 0, character: 0),
            end: RubyLsp::Interface::Position.new(line: 0, character: 4),
          ),
          severity: 1
        )

        @message_queue.push(
          method: "textDocument/publishDiagnostics",
          params: RubyLsp::Interface::PublishDiagnosticsParams.new(
            uri: uri,
            diagnostics: [diagnostic],
            version: 1 # ?
          )
        )

      rescue => e
        $stderr.puts("error in ree_formatter_diagnostic: #{e.message} : #{e.backtrace.first}")
      end
    end
  end
end
