# typed: true
# frozen_string_literal: true

require "ruby_lsp/addon"
require "sorbet-runtime"
require_relative "hanami_helpers"

require_relative "definition"
require_relative "completion"
require_relative "indexing_enhancement"
require_relative "diagnostics_runner"

module RubyLsp
  module Hanami
    class Addon < ::RubyLsp::Addon
      extend T::Sig

      # Performs any activation that needs to happen once when the language server is booted
      def activate(global_state, message_queue)
        @global_state = global_state
        @workspace_path = @global_state.workspace_path
        @index = @global_state.index
        @message_queue = message_queue

        global_state.register_formatter("hanami_diagnostics", HanamiDiagnosticsRunner.new(message_queue))
      end

      # Performs any cleanup when shutting down the server, like terminating a subprocess
      def deactivate
      end

      # Returns the name of the add-on
      def name
        "Ruby LSP Hanami"
      end

      # Defining a version for the add-on is mandatory. This version doesn't necessarily need to match the version of
      # the gem it belongs to
      def version
        "0.1.0"
      end

      def create_definition_listener(response_builder, _uri, node_context, dispatcher)
        Definition.new(response_builder, node_context, @index, dispatcher)
      end

      def create_completion_listener(response_builder, node_context, dispatcher, _uri)
        Completion.new(response_builder, node_context, dispatcher, @index, @workspace_path)
      end
    end
  end
end
