# typed: true
# frozen_string_literal: true
require 'prism'

module RubyLsp
  module Hanami
    class HanamiDiagnosticsRunner
      include RubyLsp::Requests::Support::Formatter

      def initialize(message_queue, index)
        @message_queue = message_queue
        @index = index
      end

      def run_formatting(uri, document)
        run_diagnostic(uri, document)
        document.source
      end

      def run_diagnostic(uri, document)
        ast = Prism.parse(document.source).value
        ast_root = ast.statements.body.first # this is an array, idk what the other elements would be in it though
        deps_argument = hunt_for_deps_arg(ast_root)

        return if deps_argument.nil?

        given_key = deps_argument.unescaped

        caught_ones = RubyLsp::Hanami.container_keys.select do |k, _|
          k.include?(given_key) || given_key.include?(k)
        end.values || []
        resolved_ones = @index.resolve(given_key.split(".").last,
                                       given_key.split(".")[0, given_key.split(".").length - 1]) || []

        entries = caught_ones + resolved_ones
        entries.uniq!

        if entries.empty?
          diagnostic = RubyLsp::Interface::Diagnostic.new(
            message: "test diagnostic",
            range: RubyLsp::Interface::Range.new(
              start: RubyLsp::Interface::Position.new(line: deps_argument.opening_loc.start_line - 1, character: deps_argument.opening_loc.start_column),
              end: RubyLsp::Interface::Position.new(line: deps_argument.closing_loc.end_line - 1, character: deps_argument.closing_loc.end_column),
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
        end
      end

      def hunt_for_deps_arg(node)

        node = node.first if node.is_a?(Array)
        if node.is_a?(Prism::CallNode) && node.name.to_s == "include"
          a = node.arguments.arguments[0]
          key = a
          if a.receiver.name.to_s == "Deps"
            key = a.arguments.arguments[0]
          end
          return key
        end

        if node.respond_to?(:body) && !node.body.nil? && !node.is_a?(Prism::CallNode)
          hunt_for_deps_arg(node.body)
        end
      end
    end
  end
end
