# typed: true
# frozen_string_literal: true

module RubyLsp
  module Hanami
    # top level comment
    #
    class Definition
      extend T::Sig
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
        # ??
      end

      def on_string_node_enter(node)
        # collect possible matches
        entries = if @node_context.call_node.receiver.name.to_s == "Deps"
                    # first look for potentially matching keys picked up during indexing
                    caught_ones = RubyLsp::Hanami.container_keys.select { |k, _| k.include?(node.content) }.values || []
                    resolved_ones = @index.resolve(node.content.split('.').last, node.content.split('.')[0, node.content.split('.').length - 1]) || []
                    entries = caught_ones + resolved_ones
                    entries.uniq!
                    entries
                  else
                    []
                  end

        entries.each do |entry|
          loc = entry.location
          # dont want gems :(
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
