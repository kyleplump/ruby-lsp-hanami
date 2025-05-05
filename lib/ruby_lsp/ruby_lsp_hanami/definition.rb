
module RubyLsp
  module Hanami
    class Definition

      def initialize(response_builder, node_context, dispatcher)
        p "initializing kyle"
        @response_builder = response_builder
        @node_context = node_context

        dispatcher.register(self,:on_symbol_node_enter, :on_string_node_enter, :on_class_node_enter)
      end

      def on_symbol_node_enter(node)
        p "node: #{node.value}"
        p "context: #{@node_context.call_node}"
        p "Message: #{node.message}"
        arg = @node_context.call_node&.arguments&.arguments&.first
        p "arg: #{arg}"
        @response_builder << Interface::Location.new(
          uri: 'hi :)',
          # range: range_from_locatio
        )
   
      end

      def on_string_node_enter(node)
        p "node: #{node.content}"
        p "call node: #{@node_context.call_node.name}"
        p "call node reciever: #{@node_context.call_node.receiver.name}"
        # arg = @node_context.call_node&.arguments&.arguments&.first
        # p "arg: #{arg}"
        # @response_builder << Interface::Location.new(
        #   uri: 'hi :)',
        #   # range: range_from_locatio
        # )
      end

      def on_class_node_enter(node)
        p "HI NODE!!!!"
        @response_builder << Interface::Location.new(
          uri: 'hi :)',
          # range: range_from_locatio
        )
      end
    end
  end
end