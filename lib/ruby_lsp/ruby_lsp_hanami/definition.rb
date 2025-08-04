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
        # dumb
        containers = %w[deps app]

        # collect possible matches
        entries = if containers.include?(@node_context.call_node.receiver.name.to_s.downcase)
                    # first look for potentially matching keys picked up during indexing
                    # look in both directions. for the case where the cached key is a substring or exact match of the node content
                    # -> e.g.: cached key is "repos.my_repo" and the node content is "repos.my_repo"
                    # as well as when the node content is longer than the cached key (this could happen with Slice imports)
                    # -> e.g.: cached key is "repos.my_repo" and the node content is "main_slice.repos.job_repo" (in the case that the Definition
                    # request comes from a slice)
                    caught_ones = RubyLsp::Hanami.container_keys.select do |k, _|
                      k.include?(node.content) || node.content.include?(k)
                    end.values || []
                    resolved_ones = @index.resolve(node.content.split(".").last,
                                                   node.content.split(".")[0, node.content.split(".").length - 1]) || []

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
