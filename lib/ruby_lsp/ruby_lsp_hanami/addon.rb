# typed: true
# frozen_string_literal: true

require "ruby_lsp/addon"
require "sorbet-runtime"
require_relative "hanami_helpers"

require_relative "definition"
require_relative "completion"
require_relative "indexing_enhancement"
require_relative "diagnostics_runner"
require_relative "code_lens"
require_relative "routes_walker"

module RubyLsp
  module Hanami
    # Ruby LSP Add-on for supporting the Hanami Framework - https://hanamirb.org
    class Addon < ::RubyLsp::Addon
      extend T::Sig

      # Performs any activation that needs to happen once when the language server is booted
      def activate(global_state, message_queue)
        @global_state = global_state
        @workspace_path = @global_state.workspace_path
        @index = @global_state.index
        @message_queue = message_queue
        @routes = RoutesWalker.new(project_root: @workspace_path).walk_routes_file


        global_state.register_formatter("hanami_diagnostics", HanamiDiagnosticsRunner.new(@message_queue, @global_state.index))
      end

      # Performs any cleanup when shutting down the server, like terminating a subprocess
      def deactivate; end

      def name
        "Ruby LSP Hanami"
      end

      def version
        "0.1.0"
      end

      def create_definition_listener(response_builder, _uri, node_context, dispatcher)
        Definition.new(response_builder, node_context, @index, dispatcher, @workspace_path)
      end

      def create_completion_listener(response_builder, node_context, dispatcher, _uri)
        Completion.new(response_builder, node_context, dispatcher, @index, @workspace_path)
      end

      def create_code_lens_listener(response_builder, uri, dispatcher)
        CodeLens.new(@global_state, response_builder, uri, dispatcher, @routes, @workspace_path)
      end
    end
  end
end
