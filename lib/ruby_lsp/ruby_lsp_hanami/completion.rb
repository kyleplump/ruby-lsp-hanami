module RubyLsp
  module Hanami
    class Completion
      include Requests::Support::Common

      def initialize(response_builder, node_context, dispatcher, global_index)
        @response_builder = response_builder
        @node_context = node_context
        @global_index = global_index
        dispatcher.register(
          self,
          :on_call_node_enter\
        )
      end

      def on_call_node_enter(node)

        return unless @node_context.call_node&.receiver
        receiver_name = @node_context.call_node.receiver.name.to_s

        return unless node.arguments&.arguments&.any?

        args = node.arguments.arguments.first.unescaped
        puts "Args: '#{args}'"

        if receiver_name == 'Deps'
          parents = args.split('.')[0, args.split('.').length - 1]
          needle = args.split('.').last
          puts "Parents: #{parents.inspect}"
          puts "Needle: '#{needle}'"

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
                kind: Constant::CompletionItemKind::FIELD,
              )
            end
          else
            puts "No hits found for needle: '#{needle}' with parents: #{parents.inspect}"
          end
        else
          puts "Not a Deps receiver, skipping"
        end

        puts "=== COMPLETION DEBUG END ==="
      end

      private

      def debug_index_contents
        puts "=== INDEX DEBUG ==="
        puts "Index class: #{@global_index.class}"
        puts "Total entries: #{@global_index.names.length rescue 'ERROR'}"

        # Show first 10 entries
        begin
          all_names = @global_index.names
          puts "First 10 entries: #{all_names.first(10).inspect}"
        rescue => e
          puts "Index access error: #{e.message}"
        end
        puts "=== INDEX DEBUG END ==="
      end

      def hit_from_gem?(hit)
        return false unless hit.first.uri.to_s.include?(".rbenv")
      end
    end
  end
end
