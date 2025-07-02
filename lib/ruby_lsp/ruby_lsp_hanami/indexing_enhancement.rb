module RubyLsp
  module Hanami
    class IndexingEnhancement < RubyIndexer::Enhancement
      def on_call_node_enter(call_node)
        owner = @listener.current_owner
        return unless owner

        uri = @listener.instance_variable_get(:@uri)
        index = @listener.instance_variable_get(:@index)

        return if uri.to_s.include?('.rbenv')

        if owner.respond_to?(:parent_class) && owner.parent_class.include?("::Operation")
          call_defs = index.method_completion_candidates("call", owner.name)
          RubyLsp::Hanami.set_container_key(owner.name.downcase.gsub("::", "."), call_defs.first) unless call_defs.empty?
        end
      end
    end
  end
end
