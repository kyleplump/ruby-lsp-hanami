# frozen_string_literal: true

module RubyLsp
  module Hanami
    # top level comment
    #
    class Definition
      include Requests::Support::Common

      def initialize(response_builder, node_context, index, dispatcher)
        @response_builder = response_builder
        @node_context = node_context
        @index = index

        dispatcher.register(self, :on_symbol_node_enter, :on_string_node_enter, :on_class_node_enter)
      end

      def on_symbol_node_enter(node)
        # todo
      end

      def on_class_node_enter(node)
        p "node node node: #{node.name}"
      end

      def on_string_node_enter(node)
        # p "node: #{node.content}"
        # p "call node: #{@node_context.call_node.name}"
        # p "call node reciever: #{@node_context.call_node.receiver.name}"
        # p "index?? #{@node_context.nesting}"
        # # p "index2: #{@index["call"]}"
        p "entries: #{@index["job_repo"]}"
        p "test: #{@index.resolve("Repos::JobRepo", ["::"])}"
        p "test2: #{@index.first_unqualified_const("JobRepo")}"

        if @node_context.call_node.receiver.name.to_s == "Deps"
          entries = []
          suffix = node.content.split(".").last
          entries += @index[suffix] || []
          entries += @index["call"] || [] unless node.content.include?("repos")
          entries += @index.first_unqualified_const(suffix.split("_").collect! { |w| w.capitalize }.join) || []
        end

        entries.each do |entry|
          loc = entry.location
          next if entry.file_path.include?("ruby")

          @response_builder << Interface::Location.new(
            uri: URI::Generic.from_path(
              path: entry.file_path,
              fragment: "L#{loc.start_line},#{loc.start_column + 1}-#{loc.end_line},#{loc.end_column + 1}"
            ),
            range: range_from_location(entry.location)
          )
        end
      end
    end
  end
end
