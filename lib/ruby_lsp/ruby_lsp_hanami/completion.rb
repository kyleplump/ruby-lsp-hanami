# typed: true
# frozen_string_literal: true

module RubyLsp
  module Hanami
    # top level comment
    #
    class Completion
      extend T::Sig
      include Requests::Support::Common

      def initialize(response_builder, node_context, dispatcher, global_index, workspace_path)
        @response_builder = response_builder
        @node_context = node_context
        @global_index = global_index
        @workspace_path = workspace_path
        dispatcher.register(
          self,
          :on_call_node_enter
        )
      end

      def on_call_node_enter(node)
        return unless @node_context.call_node&.receiver

        receiver_name = @node_context.call_node.receiver.name.to_s

        return unless node.arguments&.arguments&.any?

        args = node.arguments.arguments.first.unescaped

        if RubyLsp::Hanami::CONTAINERS.include?(receiver_name.downcase)
          parents = args.split('.')[0, args.split('.').length - 1]
          needle = args.split('.').last
          hits = @global_index.constant_completion_candidates(needle, parents)

          if hits&.any?
            hits.each do |hit|
              next if hit_from_gem?(hit)

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

          completion_candidates = RubyLsp::Hanami.completion_options(key: args)

          unless completion_candidates.empty?
            completion_candidates.each do |candidate|
              @response_builder << Interface::CompletionItem.new(
                label: candidate,
                detail: "Hanami dependency",
                documentation: "Dependency from Hanami container",
                label_details: Interface::CompletionItemLabelDetails.new(
                  description: "hi"
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
        return false unless hit.first&.uri.to_s.include?(".rbenv")
      end
    end
  end
end
