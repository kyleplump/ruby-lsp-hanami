# typed: true

module RubyLsp
  module Hanami
    class IndexingEnhancement < RubyIndexer::Enhancement
      extend T::Sig

      # RubyIndexer::Enhancement doesn't provide on_class_node_enter by default.
      # hook into the existing indexer and manually create entries for class nodes
      def initialize(listener)
        super(listener)

        file_path = @listener.instance_variable_get(:@uri)
        return if file_path.to_s.include?(".rbenv")

        original_method = @listener.method(:on_class_node_enter)

        @listener.define_singleton_method(:on_class_node_enter) do |node|
          result = original_method.call(node)
          # class_entry = RubyIndexer::Entry.new(node.name, file_path, node.location, "")
          # nesting, uri, location, name location , comments, parent class
          class_entry = RubyIndexer::Entry::Class.new([], file_path, node.location, node.name, node.comments, "")

          # https://gist.github.com/komasaru/b3f22d5bcb8555deea1707b84d294045
          snakified_name = result.join(".")
                                 .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                                 .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                                 .downcase

          RubyLsp::Hanami.set_container_key(snakified_name, class_entry)
        end
      end

      def on_call_node_enter(_call_node)
        owner = @listener.current_owner
        return unless owner

        uri = @listener.instance_variable_get(:@uri)
        index = @listener.instance_variable_get(:@index)
        component_parts = owner.name.split("::")
        component_parts.shift if slice?(uri)
        componentized_name = component_parts.join(".")

        return if uri.to_s.include?(".rbenv")

        # edge case for Operations, using #call as potential entry
        if owner.respond_to?(:parent_class) && owner.parent_class.include?("::Operation")
          call_defs = index.method_completion_candidates("call", owner.name)
          RubyLsp::Hanami.set_container_key(componentized_name, call_defs.first) unless call_defs.empty?
        end

        # add all indexed entries as component keys
        RubyLsp::Hanami.set_container_key(componentized_name, owner)
      end

      private

      sig { params(uri: URI).returns(T::Boolean) }
      def slice?(uri)
        uri.to_s.include?("slices/")
      end
    end
  end
end
