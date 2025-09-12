# typed: true
# frozen_string_literal: true

module RubyLsp
  module Hanami
    class Completion
      extend T::Sig
      include Requests::Support::Common

      def initialize(response_builder, node_context, dispatcher, global_index, mq, workspace_path)
        @response_builder = response_builder
        @node_context = node_context
        @global_index = global_index
        @mq = mq
        @workspace_path = workspace_path
        dispatcher.register(
          self,
          :on_call_node_enter
        )
      end

      def on_call_node_enter(node)
        return unless @node_context.call_node&.receiver

        receiver_name = @node_context.call_node.receiver.name.to_s
        p "call_node: #{@node_context.call_node.receiver.inspect}"
        return unless node.arguments&.arguments&.any?

        args = node.arguments.arguments.first.unescaped
        puts "Args: '#{args}'"
        p "receiver name: #{receiver_name}"
        if RubyLsp::Hanami::CONTAINERS.include?(receiver_name.downcase)
          parents = args.split('.')[0, args.split('.').length - 1]
          needle = args.split('.').last
          puts "Parents: #{parents.inspect}"
          puts "Needle: '#{needle}'"
          # p "thing? #{@global_index['create']}"
          hits = @global_index.constant_completion_candidates(needle, parents)
          puts "Hits found: #{hits&.length || 0}"

          if hits&.any?
            hits.each do |hit|
              next if hit.first.uri.to_s.include?(".rbenv")
              hit = hit.first

              # TODO put this in readme: must have these turned on in VS code to get completions for each keystroke
              # {
              #   "editor.quickSuggestions": {
              #     "other": true,
              #     "comments": false,
              #     "strings": true
              #   },
              #   "editor.suggestOnTriggerCharacters": true
              # }
              @response_builder << Interface::CompletionItem.new(
                label: hit.name,
                detail: "Hanami dependency",
                documentation: "Dependency from Hanami container",
                label_details: Interface::CompletionItemLabelDetails.new(
                  description: hit.file_path,
                ),
                kind: Constant::CompletionItemKind::CLASS
              )
            end
          else
            puts "No hits found for needle: '#{needle}' with parents: #{parents.inspect}"
          end

          # the thing that the user is typing may not always be the start of a 'cache key'
          # frequently, the first thing a user types may be somewhere in the middle of a cache key
          # -> e.g.: a slice could have an operation: SliceName::Namespace::Operation.
          # -> due to having to pick up extra classes in the IndexingEnhancement, the cache key would look like: "slice_name.namespace.operation"
          # -> in practice, from within a slice, the user would omit "slice_name", and immediately start typing "namespace.operation"
          #
          # due to this, we must look at all "parts" of a cached key to try and find a match. our cached key of "slice_name.namespace.operation" refers
          # to the same class as "namespace.operation" and should be considered a match

          # a hash to hold a already existing cache key as a key, and a new hash that contains that part it matched on, as well
          # as the RubyIndexer::Entry as the value
          # -> e.g.: { "slice_name.namespace.operation" => { part: "namespace", entry: RubyIndexer::Entry.... }}
          matched_cached_key_parts = {}

          RubyLsp::Hanami.container_keys.each do |k, v|
            # look for any part of the . delimited key that starts with the needle
            # this is needed for when the main entry is not the beginning of the cached
            # key (e.g. namespacing)
            key_parts = k.split(".")
            key_part_index = key_parts.index { |p| p.start_with?(needle) }

            # if this class already appears (could have duplicate entries under different keys, where the keys contain different
            # levels of namespace)
            if key_part_index && matched_cached_key_parts.none? { |_, tuple| tuple[:entry].uri.to_s == v.uri.to_s }
              matched_cached_key_parts[k] = { part: key_parts[key_part_index], entry: v }

              true
            else
              false
            end
          end

          unless matched_cached_key_parts.empty?

            matched_cached_key_parts.each do |key, tuple|
              next if key.include?("actions") # TODO probably need a way to filter things that cannot be imported

              pathname = Pathname.new(tuple[:entry].uri.to_s.gsub("file://", ""))

              @response_builder << Interface::CompletionItem.new(
                label: tuple[:part],
                detail: "Hanami dependency",
                documentation: "Dependency from Hanami container",
                label_details: Interface::CompletionItemLabelDetails.new(
                  description: pathname.relative_path_from(@workspace_path)
                  # description: entry.name
                ),
                kind: Constant::CompletionItemKind::CLASS
              )
            end
          end
        else
          puts "Not a Deps receiver, skipping"
        end
      end

      private

      def hit_from_gem?(hit)
        return false unless hit.first.uri.to_s.include?(".rbenv")
      end
    end
  end
end
