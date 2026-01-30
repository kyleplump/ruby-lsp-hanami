module RubyLsp
  module Hanami
    class CodeLens
      include Requests::Support::Common

      def initialize(global_state, response_builder, uri, dispatcher, routes)
        @global_state = global_state
        @response_builder = response_builder
        @path = uri.to_standardized_path
        @group_id = 1
        @group_id_stack = []
        @constant_name_stack = []
        @module_nesting = nil
        @routes = routes

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
        # add_jump_to_view_class_file(node)
        # add_jump_to_template_file(node)
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
        class_name = @constant_name_stack.last # : as !nil

        p "module nesting: #{@module_nesting}"
        p "routes!!!: #{@routes}"

        # class_name, = @constant_name_stack.last # : as !nil

        # # TODO: Fetch real route and source location
        # route = { source_location: ["/Users/afomera/Projects/hanami-projects/learn_hanakai/config/routes.rb", 14],
        #           verb: "GET", path: "/about" }
        # file_path, line = route[:source_location]

        # @response_builder << create_code_lens(
        #   node,
        #   title: "#{route[:verb]} #{route[:path]}",
        #   command_name: "rubyLsp.openFile",
        #   arguments: [["file://#{file_path}#L#{line}"]],
        #   data: { type: "file" }
        # )
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
        # The controller name is the second last element in the stack
        puts "@constant_name_stack=#{@constant_name_stack.inspect}"
        p "path: #{@path}"
        controller_name = @constant_name_stack[-2][0] # e.g. "EmailSubscriptions"

        # Handle the case where there is a capital letter in the controller name, e.g. "EmailSubscriptions" -> "email_subscriptions"
        controller_name = controller_name.gsub(/([a-z])([A-Z])/, "\\1_\\2").downcase

        action_name = @constant_name_stack.last[0].downcase # e.g. "Index"

        puts "Looking for template for action #{controller_name}##{action_name}"

        # controller_name = class_name
        #                   .delete_suffix("Action")
        #                   .gsub(/([a-z])([A-Z])/, "\\1_\\2")
        #                   .gsub("::", "/")
        #                   .downcase


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
        # @constant_name_stack looks like this: [["LearnHanakai", nil], ["Actions", nil], ["About", nil], ["Index", "LearnHanakai::Action"]]
        # The controller name is the second last element in the stack
        controller_name = @constant_name_stack[-2][0] # e.g. "EmailSubscriptions"

        # Handle the case where there is a capital letter in the controller name, e.g. "EmailSubscriptions" -> "email_subscriptions"
        controller_name = controller_name.gsub(/([a-z])([A-Z])/, "\\1_\\2").downcase

        action_name = @constant_name_stack.last[0].downcase # e.g. "Index"

        puts "Looking for view for action #{controller_name}##{action_name}"

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

        if @module_nesting.nil?
          @module_nesting = node.constant_path.slice.downcase
        else
          @module_nesting += ".#{node.constant_path.slice.downcase}"
        end
      end

      def on_module_node_leave(node)
        @constant_name_stack.pop
      end

      private

      def action?
        class_name, superclass_name = @constant_name_stack.last
        return false unless class_name && superclass_name

        superclass_name.end_with?("Action")
        # @constant_name_stack.last&.end_with?("Controller")
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
