
module RubyLsp
  module Hanami
    class Definition
      include Requests::Support::Common
      
      def initialize(response_builder, node_context, index, dispatcher)
        p "initializing kyle"
        @response_builder = response_builder
        @node_context = node_context
        @index = index

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
    
        p "indexed? #{@index.indexed?('create')}"
        return unless @index.indexed?('create')

        entries = @index['create']

        entries.each do |entry|
          p "entry loc: #{entry.location}"
          loc = entry.location
          @response_builder << Interface::Location.new(
            uri: URI::Generic.from_path(
              path: entry.file_path,
              fragment: "L#{loc.start_line},#{loc.start_column + 1}-#{loc.end_line},#{loc.end_column + 1}"
            ),
            range: range_from_location(entry.location)
          )
        end

        # p "index: #{@index.pretty_print['jobs.create']}"
        # @index.each do |i|
        #   p "i is: #{i}"
        # end
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