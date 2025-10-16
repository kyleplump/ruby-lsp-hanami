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

        # TODO: make this name less bad and also maybe dont do this
        all_keys = RubyLsp::Hanami.container_keys.keys
        has_given_key = false
        all_keys.each do |key|
          has_given_key = true if key.end_with?(given_key)
        end

        # if there are no diagnostic errors, push an empty list to clear any previously
        # sent diagnostics for the file
        # @see https://dart.googlesource.com/sdk/%2B/fe6fc7803dd69c2ea4a1471d5898b4f4e13c0f99/pkg/analysis_server/tool/lsp_spec/lsp_specification.md#publishdiagnostics-notification-arrow_left
        diagnostics = if has_given_key
                        []
                      else
                        [
                          RubyLsp::Interface::Diagnostic.new(
                            message: "Key: \"#{given_key}\" not found.",
                            range: RubyLsp::Interface::Range.new(
                              start: RubyLsp::Interface::Position.new(line: deps_argument.opening_loc.start_line - 1, character: deps_argument.opening_loc.start_column),
                              end: RubyLsp::Interface::Position.new(line: deps_argument.closing_loc.end_line - 1, character: deps_argument.closing_loc.end_column),
                            ),
                            severity: Constant::DiagnosticSeverity::ERROR
                          )
                        ]
                      end

        @message_queue.push(
          method: "textDocument/publishDiagnostics",
          params: RubyLsp::Interface::PublishDiagnosticsParams.new(
            uri: uri,
            diagnostics: diagnostics,
            version: 1 # ?
          )
        )
      end

      private

      def hunt_for_deps_arg(node)
        node = node.first if node.is_a?(Array)

        if node.is_a?(Prism::CallNode) && node.name.to_s == "include"
          args = node.arguments.arguments[0]
          key = args.receiver.name.to_s == "Deps" ? args.arguments.arguments[0] : args

          return key
        end

        hunt_for_deps_arg(node.body) if node.respond_to?(:body) && !node.body.nil? && !node.is_a?(Prism::CallNode)
      end
    end
  end
end
