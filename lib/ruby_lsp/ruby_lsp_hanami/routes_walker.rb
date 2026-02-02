# frozen_string_literal: true

require "prism"

class RoutesWalker

  def initialize(project_root:)
    routes_file = File.join(project_root, "config", "routes.rb")
    routes_content = File.read(routes_file)
    @routes_ast = Prism.parse(routes_content)
  end

  def walk_routes_file
    routes = []
    app_module = @routes_ast.value.statements.body.first
    route_definitions = app_module.body.body.first.body&.body

    route_definitions.each do |definition|
      if definition.is_a?(Prism::CallNode)
        if definition.name == :slice
          routes += process_routes_block(block: definition.block, containing_slice: definition.arguments.arguments.first.unescaped)
        else
          routes << process_line_route(call_node: definition)
        end
      end
    end

    routes
  end

  private

  def process_line_route(call_node:)
    {
      type: call_node.name,
      location: call_node.arguments.arguments[1].elements.first.value.location,
      key: call_node.arguments.arguments[1].elements.first.value.unescaped,
      route: call_node.arguments.arguments.first.unescaped
    }
  end

  def process_routes_block(block:, containing_slice: nil)
    block_routes = []

    block.body.body.each do |definition|
      base_info = process_line_route(call_node: definition)
      block_routes << {
        containing_slice: containing_slice,
        **base_info
      }
    end

    block_routes
  end
end
