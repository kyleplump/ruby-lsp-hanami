# frozen_string_literal: true

module RubyLsp
  module Hanami
    class CodeLens
      include Requests::Support::Common

      def initialize(global_state, response_builder, uri, dispatcher, routes, project_root)
        @global_state = global_state
        @response_builder = response_builder
        @path = uri.to_standardized_path
        @group_id = 1
        @group_id_stack = []
        @constant_name_stack = []
        @routes = routes
        @project_root = project_root

        dispatcher.register(
          self,
          :on_call_node_enter,
          :on_class_node_enter,
          :on_def_node_enter,
          :on_class_node_leave,
          :on_module_node_enter,
          :on_module_node_leave
        )
      end

      def on_def_node_enter(node)
        return unless action?

        add_route_code_lens_to_action(node)
        add_jump_to_view_class_file(node)
        add_jump_to_template_file(node)
      end

      def on_call_node_enter(node)
        # puts "Visiting call node: #{node.name}"
        # content = extract_test_case_name(node)
        # return unless content

        # line_number = node.location.start_line
        # command = "#{test_command} #{@path}:#{line_number}"
        # add_test_code_lens(node, name: content, command: command, kind: :example)
      end

      def add_route_code_lens_to_action(node)
        global_namespace = @constant_name_stack.first.first.downcase
        containing_module = @constant_name_stack[-2].first.downcase
        controller = @constant_name_stack.last
        class_name = controller.first.downcase

        # extreme rough first draft, obviously meant to be optimized needed
        # something working
        routes_with_class_as_key = @routes.filter do |route|
          route[:key].include?(class_name)
        end

        potential_key = "#{containing_module}.#{class_name}"

        match = routes_with_class_as_key.find do |route|
          route[:containing_slice] == global_namespace && route[:key].include?(potential_key)
        end

        return unless match

        file_path = File.join(@project_root, "config", "routes.rb")

        @response_builder << create_code_lens(
          node,
          title: "#{match[:type].upcase} #{match[:route]}",
          command_name: "rubyLsp.openFile",
          arguments: [["file://#{file_path}#L#{match[:location].start_line}"]],
          data: { type: "file" }
        )
      end

      # Given a Hanami action like:
      #
      # module LearnHanakai
      #   module Actions
      #     module About
      #       class Index < LearnHanakai::Action

      #         def handle(request, response)
      #         end
      #       end
      #     end
      #   end
      # end
      #
      # this method will try to find a template file in the `app/templates/about/` folder with the same name as the action
      # (e.g. `index.html.erb`, `index.html.haml`, etc.) and add a "Jump to template" code lens to the action definition
      #
      def add_jump_to_template_file(node)
        # @constant_name_stack looks like this: [["LearnHanakai", nil], ["Actions", nil], ["About", nil], ["Index", "LearnHanakai::Action"]]
        # ["LearnHanakai", nil], ["Actions", nil], ["EmailSubscriptions", nil], ["Create", "LearnHanakai::Action"]] <-- example too
        view_uris = Dir.glob("#{associated_filepath("templates")}*").filter_map do |path|
          # it's possible we could have a directory with the same name as the action, so we need to skip those
          next if File.directory?(path)

          URI::Generic.from_path(path: path).to_s
        end

        if view_uris.empty?
          # TODO: return nil if no template is found so the editor is clean?
          return @response_builder << create_code_lens(
            node,
            title: "No template found",
            command_name: "",
            arguments: [],
            data: { type: "file" }
          )
        end

        @response_builder << create_code_lens(
          node,
          title: "Jump to template",
          command_name: "rubyLsp.openFile",
          arguments: [view_uris],
          data: { type: "file" }
        )
      end

      def add_jump_to_view_class_file(node)
        view_uris = Dir.glob("#{associated_filepath("views")}*").filter_map do |path|
          # it's possible we could have a directory with the same name as the action, so we need to skip those
          next if File.directory?(path)

          URI::Generic.from_path(path: path).to_s
        end

        return if view_uris.empty?

        @response_builder << create_code_lens(
          node,
          title: "Jump to view",
          command_name: "rubyLsp.openFile",
          arguments: [view_uris],
          data: { type: "file" }
        )
      end

      def on_class_node_enter(node)
        class_name = node.constant_path.slice
        superclass_name = node.superclass&.slice

        @constant_name_stack << [class_name, superclass_name]
      end

      def on_class_node_leave(node)
        class_name = node.constant_path.slice

        @group_id_stack.pop if class_name.end_with?("Test")
        @constant_name_stack.pop
      end

      def on_module_node_enter(node)
        @constant_name_stack << [node.constant_path.slice, nil]
      end

      def on_module_node_leave(_node)
        @constant_name_stack.pop
      end

      private

      def action?
        class_name, superclass_name = @constant_name_stack.last
        return false unless class_name && superclass_name

        superclass_name.end_with?("Action")
      end

      def from_slice?
        @path.include?("slices/")
      end

      # TODO: better name
      def associated_filepath(resource_type)
        slice_or_app_delimiter = from_slice? ? "slices" : "app"
        file_loc_prefix, path = @path.split(slice_or_app_delimiter)

        file_loc_prefix + slice_or_app_delimiter + path.gsub("actions", resource_type).delete_suffix(File.extname(path))
      end
    end
  end
end
