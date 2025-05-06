require 'ruby_lsp/addon'

require_relative 'definition'

module RubyLsp
  module Hanami
    class Addon < ::RubyLsp::Addon
      extend T::Sig

      # Performs any activation that needs to happen once when the language server is booted
      def activate(global_state, message_queue)
        @global_state = global_state
        @index = global_state.index
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

      def create_definition_listener(response_builder, uri, node_context, dispatcher)
        Definition.new(response_builder, node_context, @index, dispatcher)
      end
    end
  end
end